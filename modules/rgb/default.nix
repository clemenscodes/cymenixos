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

  # Client side: talks to the SDK servers only, never to hardware (--nodetect).
  # rgb-off snapshots the current look per server, rgb-on restores it.
  mkRgbScript = name: body:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [rgb.package pkgs.coreutils];
      text = ''
        state="''${XDG_STATE_HOME:-$HOME/.local/state}/openrgb-client"
        mkdir -p "$state"
        client() {
          openrgb --nodetect --noautoconnect --config "$state" --client "$1" "''${@:2}"
        }
        status=0
        servers=(${lib.escapeShellArgs servers})
        for server in "''${servers[@]}"; do
          profile="on-''${server//[^0-9]/_}"
          ${body}
        done
        exit "$status"
      '';
    };

  rgb-off = mkRgbScript "rgb-off" ''
    client "$server" --save-profile "$profile" >/dev/null 2>&1 || true
    client "$server" ${lib.escapeShellArgs rgb.offArgs} >/dev/null 2>&1 || status=1
  '';

  rgb-on = mkRgbScript "rgb-on" ''
    if [ -e "$state/$profile.orp" ]; then
      client "$server" --profile "$profile" >/dev/null 2>&1 || status=1
    fi
  '';
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
        offArgs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = ["--mode" "off"];
          description = "OpenRGB client arguments rgb-off applies to all devices.";
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

    environment.systemPackages = [rgb.package rgb-off rgb-on];
  };
}
