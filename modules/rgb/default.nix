{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
  rgb = cfg.rgb;

  # OpenRGB with an allowlist that is enforced in code, not only in settings:
  # - A detector that is not listed in the settings is DISABLED. Upstream treats it as
  #   enabled, and after the first run writes every missing detector back as enabled,
  #   so a new detector from an update would start probing buses on its own.
  # - Pre-detection hooks (Razer ARGB / Roccat resets) and dynamic detectors (QMK scans)
  #   run unconditionally upstream; they are removed.
  # Only the detectors in `modules.rgb.detectors` ever touch hardware.
  allowlistedOpenrgb = pkgs.openrgb.overrideAttrs (old: {
    postPatch =
      (old.postPatch or "")
      + ''
        substituteInPlace DetectionManager.cpp \
          --replace-fail 'bool this_device_enabled = true;' 'bool this_device_enabled = false;' \
          --replace-fail 'device_detector_default_enabled.push_back(enabled_by_default);' 'device_detector_default_enabled.push_back(false);' \
          --replace-fail 'block.enabled_by_default    = enabled_by_default;' 'block.enabled_by_default    = false;' \
          --replace-fail 'pre_detection_hooks[hook_idx]();' '/* cymenixos: pre-detection hooks disabled */' \
          --replace-fail 'dynamic_detectors[detector_idx]();' '/* cymenixos: dynamic detectors disabled */'
      '';
  });

  stateDir = "/var/lib/OpenRGB";

  settingsFile = pkgs.writeText "OpenRGB.json" (builtins.toJSON (lib.recursiveUpdate {
      Detectors.detectors = lib.genAttrs rgb.detectors (_: true);
    }
    rgb.settings));

  # udev: the service account may open exactly these device nodes, nothing else.
  usbRules = lib.concatMapStrings (d: ''
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="${d.vendor}", ATTRS{idProduct}=="${d.product}", GROUP="openrgb", MODE="0660"
    SUBSYSTEM=="usb", ATTR{idVendor}=="${d.vendor}", ATTR{idProduct}=="${d.product}", GROUP="openrgb", MODE="0660"
  '')
  rgb.usbDevices;
  i2cRules = lib.concatMapStrings (b:
    if b.pciDevice != null
    then ''
      SUBSYSTEM=="i2c-dev", KERNELS=="${b.pciDevice}", GROUP="openrgb", MODE="0660"
    ''
    else ''
      SUBSYSTEM=="i2c-dev", ATTR{name}=="${b.name}", GROUP="openrgb", MODE="0660"
    '')
  rgb.i2cBuses;

  # libvirt "0000:03:00.0" -> XPath predicate on the hostdev source address
  pciXPath = addr: let
    parts = lib.splitString ":" addr;
    slotFn = lib.splitString "." (builtins.elemAt parts 2);
  in "@domain='0x${builtins.elemAt parts 0}' and @bus='0x${builtins.elemAt parts 1}' and @slot='0x${builtins.elemAt slotFn 0}' and @function='0x${toString (lib.toInt (builtins.elemAt slotFn 1))}'";

  # Stops OpenRGB before a VM that passes through one of the listed GPUs takes it:
  # libvirt unbinds the GPU from its host driver, and an i2c bus that OpenRGB keeps
  # open would block that unbind. OpenRGB starts again once the VM released the GPU.
  vmHook = pkgs.writeShellScript "openrgb-vm-hook" ''
    set -eu
    domain="$1"
    marker="/run/openrgb-paused-by-$domain"
    case "$2/$3" in
      prepare/begin)
        hits=$(${pkgs.libxml2}/bin/xmllint --xpath "count(/domain/devices/hostdev[@type='pci']/source/address[${lib.concatMapStringsSep " or " (a: "(" + pciXPath a + ")") rgb.vmPassthrough.pciDevices}])" - 2>/dev/null || echo 0)
        if [ "$hits" != "0" ]; then
          touch "$marker"
          ${pkgs.systemd}/bin/systemctl stop openrgb.service
        fi
        ;;
      release/end)
        if [ -e "$marker" ]; then
          rm -f "$marker"
          ${pkgs.systemd}/bin/systemctl start --no-block openrgb.service
        fi
        ;;
    esac
  '';

  servers = ["127.0.0.1:${toString rgb.port}"] ++ rgb.extraServers;

  # Client side: talks to the SDK servers only, through openrgb-python. The openrgb CLI
  # client exits before its updates reach the server, so changes were applied at random.
  #
  # "On" is declarative: devices cannot always report their running effect (Corsair DRAM
  # and Zotac GPUs report a default instead), so a snapshot taken before switching off
  # restores black. rgb-on applies modules.rgb.onModes by device name instead.
  # "Off" picks per device: Off, else Direct in black, else Static in black.
  rgbConfig = pkgs.writeText "rgb-control.json" (builtins.toJSON {
    inherit servers;
    onModes = rgb.onModes;
  });

  rgb-control = pkgs.writers.writePython3Bin "rgb-control" {
    libraries = [pkgs.python3Packages.openrgb-python];
    flakeIgnore = ["E501"];
  } ''
    """Switch all SDK servers' devices on (declared modes), off, or set the global brightness.

    State (on/off, global brightness in percent) lives in $XDG_STATE_HOME/rgb-control/state.json,
    so rgb-on restores the last brightness and the bar can show the current state.
    """
    import json
    import os
    import sys
    import time
    import warnings

    from openrgb import OpenRGBClient
    from openrgb.utils import RGBColor

    BLACK = RGBColor(0, 0, 0)
    STATE_DIR = os.path.join(os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state")), "rgb-control")
    STATE_FILE = os.path.join(STATE_DIR, "state.json")


    def load_state():
        try:
            with open(STATE_FILE) as f:
                state = json.load(f)
        except (OSError, ValueError):
            state = {}
        return {"on": state.get("on", True), "brightness": int(state.get("brightness", 100))}


    def save_state(state):
        os.makedirs(STATE_DIR, exist_ok=True)
        tmp = STATE_FILE + ".tmp"
        with open(tmp, "w") as f:
            json.dump(state, f)
        os.replace(tmp, STATE_FILE)


    def scale(low, high, percent):
        # percent of a device range; some ranges count downwards (low > high)
        return round(low + (high - low) * percent / 100)


    def find_mode(device, name):
        for mode in device.modes:
            if mode.name.lower() == name.lower():
                return mode
        return None


    def wanted_for(device, on_modes):
        serial = getattr(device.metadata, "serial", "") or ""
        return on_modes.get(serial) or on_modes.get(device.name)


    def has_brightness(mode):
        low = getattr(mode, "brightness_min", None)
        high = getattr(mode, "brightness_max", None)
        return low is not None and high is not None and low != high


    def off_mode(device):
        for name in ("Off", "Direct", "Static"):
            if find_mode(device, name) is not None:
                return name
        return None


    def switch_off(device, name):
        mode = find_mode(device, name)
        if mode.colors:
            mode.colors = [BLACK] * len(mode.colors)
        device.set_mode(mode)
        if name == "Direct" and device.leds:
            device.set_color(BLACK)


    def is_black(color):
        return color.red == 0 and color.green == 0 and color.blue == 0


    def check_off(name):
        def check(device):
            if device.modes[device.active_mode].name.lower() != name.lower():
                return False
            return name != "Direct" or all(is_black(c) for c in device.colors)
        return check


    def switch_on(device, wanted, global_brightness):
        mode = find_mode(device, wanted["mode"])
        colors = [RGBColor.fromHEX(c) for c in wanted.get("colors") or []]
        if colors and mode.colors:
            mode.colors = [colors[i % len(colors)] for i in range(len(mode.colors))]
        if wanted.get("speed") is not None and mode.speed_min != mode.speed_max:
            mode.speed = scale(mode.speed_min, mode.speed_max, wanted["speed"])
        if wanted.get("direction") is not None:
            mode.direction = wanted["direction"]
        if has_brightness(mode):
            base = wanted.get("brightness")
            base = 100 if base is None else base
            mode.brightness = scale(mode.brightness_min, mode.brightness_max, base * global_brightness / 100)
        device.set_mode(mode)
        if colors and mode.name.lower() == "direct" and device.leds:
            device.set_color(colors[0])


    def check_mode(name):
        return lambda device: device.modes[device.active_mode].name.lower() == name.lower()


    def run(config, plan):
        """Apply plan(device) -> (apply, check) | None on every server and verify the result.

        SDK colour and mode updates are fire-and-forget, so after applying, a synchronous
        refresh waits for the server and the state is read back. Devices that do not show
        the expected state are applied again (slow buses: SMBus RAM, wireless fans), and a
        stalled server gets a fresh connection, so one stuck device never skips the rest.
        """
        ok = True
        for server in config["servers"]:
            host, _, port = server.rpartition(":")
            todo = None
            names = {}
            for attempt in range(3):
                try:
                    client = OpenRGBClient(host, int(port), "rgb-control")
                except Exception as error:
                    print(f"{server}: {error}", file=sys.stderr)
                    time.sleep(1)
                    continue
                try:
                    checks = {}
                    for index, device in enumerate(client.devices):
                        if todo is not None and index not in todo:
                            continue
                        step = plan(device)
                        if step is None:
                            continue
                        apply, check = step
                        names[index] = device.name
                        try:
                            apply(device)
                            checks[index] = check
                        except Exception as error:
                            print(f"{device.name}: {error}", file=sys.stderr)
                            checks[index] = None
                    # the refresh is synchronous; the pause only lets queued colour updates land
                    time.sleep(0.3 if attempt == 0 else 1)
                    client.update()
                    todo = {i for i, check in checks.items() if check is None or not check(client.devices[i])}
                except Exception as error:
                    print(f"{server}: {error}", file=sys.stderr)
                finally:
                    try:
                        client.disconnect()
                    except Exception:
                        pass
                if todo == set():
                    break
                time.sleep(1)
            if todo != set():
                failed = sorted(names.get(i, f"device {i}") for i in (todo or names))
                print(f"{server}: not applied: {', '.join(failed) or 'all devices'}", file=sys.stderr)
                ok = False
        return ok


    def on_step(device, on_modes, global_brightness):
        wanted = wanted_for(device, on_modes)
        if wanted is None:
            return None
        if find_mode(device, wanted["mode"]) is None:
            print(f"{device.name}: no mode {wanted['mode']!r}", file=sys.stderr)
            return None
        return (lambda d: switch_on(d, wanted, global_brightness)), check_mode(wanted["mode"])


    def main():
        warnings.simplefilter("ignore")
        command = sys.argv[1]
        config = json.load(open(sys.argv[2]))
        on_modes = config["onModes"]
        state = load_state()

        if command == "status":
            print(json.dumps(state))
            return
        if command == "off":
            def off(device):
                name = off_mode(device)
                if name is None:
                    return None
                return (lambda d: switch_off(d, name)), check_off(name)
            ok = run(config, off)
            state["on"] = False
        elif command == "on":
            ok = run(config, lambda device: on_step(device, on_modes, state["brightness"]))
            state["on"] = True
        elif command == "toggle":
            save_state(state)
            os.execv(sys.argv[0], [sys.argv[0], "off" if state["on"] else "on", sys.argv[2]])
        elif command == "brightness":
            value = sys.argv[3]
            if value[0] in "+-":
                state["brightness"] = max(0, min(100, state["brightness"] + int(value)))
            else:
                state["brightness"] = max(0, min(100, int(value)))
            ok = True
            if state["on"]:
                def dim(device):
                    step = on_step(device, on_modes, state["brightness"])
                    wanted = wanted_for(device, on_modes)
                    return step if step and has_brightness(find_mode(device, wanted["mode"])) else None
                ok = run(config, dim)
        else:
            sys.exit("usage: rgb-control on|off|toggle|status|brightness [+-]PERCENT CONFIG")
        save_state(state)
        print(json.dumps(state))
        sys.exit(0 if ok else 1)


    main()
  '';

  # The OpenRGB GUI connects to every server in Client.clients at startup. It connects to
  # the local server on its own, so only the extra servers are listed. Everything else in
  # the user's OpenRGB.json stays as the GUI wrote it.
  clientConfig = pkgs.writeShellScript "openrgb-client-config" ''
    set -eu
    dir="''${XDG_CONFIG_HOME:-$HOME/.config}/OpenRGB"
    file="$dir/OpenRGB.json"
    mkdir -p "$dir"
    [ -s "$file" ] || echo '{}' > "$file"
    ${lib.getExe pkgs.jq} --argjson clients ${lib.escapeShellArg (builtins.toJSON (map (server: let
        parts = lib.splitString ":" server;
      in {
        ip = builtins.head parts;
        port = lib.toInt (lib.last parts);
      })
      rgb.extraServers))} '.Client.clients = $clients' "$file" > "$file.tmp"
    mv "$file.tmp" "$file"
  '';

  mkRgbCommand = name: args: pkgs.writeShellScriptBin name ''exec ${rgb-control}/bin/rgb-control ${args} ${rgbConfig} "$@"'';
  rgb-off = mkRgbCommand "rgb-off" "off";
  rgb-on = mkRgbCommand "rgb-on" "on";
  rgb-toggle = mkRgbCommand "rgb-toggle" "toggle";
  rgb-status = mkRgbCommand "rgb-status" "status";
  # rgb-brightness 50 | +25 | -25
  rgb-brightness = pkgs.writeShellScriptBin "rgb-brightness" ''exec ${rgb-control}/bin/rgb-control brightness ${rgbConfig} "$1"'';
in {
  options = {
    modules = {
      rgb = {
        enable = lib.mkEnableOption "Enable RGB" // {default = false;};
        package = lib.mkOption {
          type = lib.types.package;
          default = allowlistedOpenrgb;
          defaultText = lib.literalMD "nixpkgs OpenRGB, patched so that only allowlisted detectors run";
          description = "OpenRGB package. The default enforces the detector allowlist in code.";
        };
        port = lib.mkOption {
          type = lib.types.port;
          default = 6742;
          description = "SDK server port (bound to 127.0.0.1 only).";
        };
        detectors = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          example = ["ASUS Aura Motherboard" "Corsair DRAM"];
          description = ''
            OpenRGB detector names that may run, exactly as OpenRGB registers them.
            Every other detector stays off, including ones added by future OpenRGB versions.
          '';
        };
        usbDevices = lib.mkOption {
          type = lib.types.listOf (lib.types.submodule {
            options = {
              vendor = lib.mkOption {
                type = lib.types.strMatching "[0-9a-f]{4}";
                description = "USB vendor id, lowercase hex.";
              };
              product = lib.mkOption {
                type = lib.types.strMatching "[0-9a-f]{4}";
                description = "USB product id, lowercase hex.";
              };
            };
          });
          default = [];
          description = "USB/HID devices the OpenRGB service account may open.";
        };
        i2cBuses = lib.mkOption {
          type = lib.types.listOf (lib.types.submodule {
            options = {
              pciDevice = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                example = "0000:01:00.0";
                description = "Grant the i2c buses of this PCI device (e.g. a GPU).";
              };
              name = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                example = "SMBus PIIX4 adapter port 0 at 0b00";
                description = "Grant the i2c bus with this adapter name (e.g. the SMBus port of the RAM).";
              };
            };
          });
          default = [];
          description = ''
            i2c/SMBus adapters the OpenRGB service account may open. Without any, i2c-dev is
            not loaded and OpenRGB cannot reach RAM or GPU buses at all.
          '';
        };
        vmPassthrough = {
          pciDevices = lib.mkOption {
            type = lib.types.listOf (lib.types.strMatching "[0-9a-f]{4}:[0-9a-f]{2}:[0-9a-f]{2}\\.[0-7]");
            default = [];
            example = ["0000:03:00.0"];
            description = "GPUs handed to libvirt VMs; OpenRGB is stopped while such a VM holds them.";
          };
        };
        settings = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = {};
          description = "Extra OpenRGB.json settings, merged over the generated detector allowlist.";
        };
        extraServers = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          example = ["127.0.0.1:6743"];
          description = "Further OpenRGB SDK servers rgb-on/rgb-off switch, e.g. lian-li-linux.";
        };
        onModes = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule {
            options = {
              mode = lib.mkOption {
                type = lib.types.str;
                example = "Rainbow Wave";
                description = "OpenRGB mode name, as listed by `openrgb --client --list-detailed`.";
              };
              colors = lib.mkOption {
                type = lib.types.listOf (lib.types.strMatching "[0-9A-Fa-f]{6}");
                default = [];
                description = "Colours (RRGGBB) for modes that take them, repeated to fill the mode's colour slots.";
              };
              speed = lib.mkOption {
                type = lib.types.nullOr (lib.types.ints.between 0 100);
                default = null;
                description = "Effect speed in percent of the device's range (0 = slowest), for modes that have one.";
              };
              brightness = lib.mkOption {
                type = lib.types.nullOr (lib.types.ints.between 0 100);
                default = null;
                description = "Brightness in percent of the device's range (default 100), scaled by rgb-brightness.";
              };
              direction = lib.mkOption {
                type = lib.types.nullOr (lib.types.ints.between 0 5);
                default = null;
                description = "OpenRGB direction: 0 left, 1 right, 2 up, 3 down, 4 horizontal, 5 vertical.";
              };
            };
          });
          default = {};
          example = {"Corsair Dominator Titanium RGB DDR5".mode = "Rainbow Wave";};
          description = ''
            What rgb-on sets, keyed by device serial (as reported over the SDK) or by device
            name (all devices with that name). A serial key wins over a name key.
          '';
        };
        schedule = {
          off = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "23:00";
            description = "systemd OnCalendar time to switch the LEDs off (rgb-off).";
          };
          on = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "08:00";
            description = "systemd OnCalendar time to switch the LEDs back on (rgb-on).";
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && rgb.enable) {
    assertions = [
      {
        assertion = lib.all (b: (b.pciDevice == null) != (b.name == null)) rgb.i2cBuses;
        message = "modules.rgb.i2cBuses: set exactly one of pciDevice or name per entry.";
      }
    ];

    users = {
      groups.openrgb = {};
      users.openrgb = {
        isSystemUser = true;
        group = "openrgb";
        home = stateDir;
      };
    };

    boot.kernelModules = lib.optional (rgb.i2cBuses != []) "i2c-dev";

    services.udev.extraRules = usbRules + i2cRules;

    systemd.services.openrgb = {
      description = "OpenRGB SDK server (allowlisted detectors, unprivileged)";
      wantedBy = ["multi-user.target"];
      after = ["systemd-udevd.service" "systemd-modules-load.service"];
      serviceConfig = {
        User = "openrgb";
        Group = "openrgb";
        StateDirectory = "OpenRGB";
        StateDirectoryMode = "0750";
        WorkingDirectory = stateDir;
        # Settings come from Nix on every start; OpenRGB may write the file at runtime.
        ExecStartPre = "${pkgs.coreutils}/bin/install -m 0640 ${settingsFile} ${stateDir}/OpenRGB.json";
        ExecStart = lib.escapeShellArgs [
          (lib.getExe rgb.package)
          "--server"
          "--server-host"
          "127.0.0.1"
          "--server-port"
          (toString rgb.port)
          "--config"
          stateDir
        ];
        Restart = "on-failure";
        RestartSec = 5;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        CapabilityBoundingSet = "";
        RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK"];
      };
    };

    virtualisation.libvirtd.hooks.qemu = lib.mkIf (rgb.vmPassthrough.pciDevices != []) {
      openrgb = vmHook;
    };

    systemd.user = {
      services = {
        openrgb-client-config = {
          description = "Point the OpenRGB GUI at the extra SDK servers";
          wantedBy = ["default.target"];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = clientConfig;
          };
        };
        rgb-off = {
          description = "Switch RGB lighting off";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${rgb-off}/bin/rgb-off";
          };
        };
        rgb-on = {
          description = "Restore RGB lighting";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${rgb-on}/bin/rgb-on";
          };
        };
      };
      timers =
        lib.optionalAttrs (rgb.schedule.off != null) {
          rgb-off = {
            wantedBy = ["timers.target"];
            timerConfig.OnCalendar = rgb.schedule.off;
          };
        }
        // lib.optionalAttrs (rgb.schedule.on != null) {
          rgb-on = {
            wantedBy = ["timers.target"];
            timerConfig.OnCalendar = rgb.schedule.on;
          };
        };
    };

    environment.systemPackages = [rgb.package rgb-off rgb-on rgb-toggle rgb-status rgb-brightness];
  };
}
