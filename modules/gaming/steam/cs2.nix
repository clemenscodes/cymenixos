{
  inputs,
  pkgs,
  lib,
  ...
}:
{ config, ... }:
let
  cfg = config.modules.gaming.steam.cs2;
  hcfg = cfg.hyprland;

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # VDF key-value line: two tabs between key and value (matches CS2's own format)
  vdfLine = k: v: "\t\t\"${k}\"\t\t\"${v}\"";

  # Generate a VDF convars/bindings block from an attrset
  vdfAttrs = attrs: lib.concatStringsSep "\n" (lib.mapAttrsToList vdfLine attrs);

  # ---------------------------------------------------------------------------
  # Steam launch options string (stored in localconfig.vdf via activation)
  # Uses Steam's %command% mechanism so gamescope wraps the CS2 executable
  # directly — works correctly whether Steam is already running or not.
  # ---------------------------------------------------------------------------

  launchOptions =
    let
      envStr = lib.concatStringsSep " " (lib.mapAttrsToList (k: v: "${k}=${v}") cfg.env);
      gamescopeStr = lib.optionalString cfg.gamescope.enable
        "gamescope ${lib.concatStringsSep " " cfg.gamescope.args} -- ";
      gameArgsStr = lib.concatStringsSep " " cfg.gameArgs;
    in
    lib.concatStringsSep " " (lib.filter (s: s != "") [
      envStr
      "${gamescopeStr}%command%"
      gameArgsStr
    ]);

  # Python script that patches localconfig.vdf with the CS2 launch options.
  # Reads the launch options string from $CS2_LAUNCH_OPTS to avoid shell quoting issues.
  python = pkgs.python3.withPackages (ps: [ ps.vdf ]);
  updateLocalconfigScript = pkgs.writeText "update-cs2-localconfig.py" ''
    import os, sys, vdf

    path = sys.argv[1]
    opts = os.environ["CS2_LAUNCH_OPTS"]

    try:
        with open(path, encoding="utf-8") as f:
            data = vdf.load(f)

        apps = data["UserLocalConfigStore"]["Software"]["Valve"]["Steam"]["apps"]
        if "730" not in apps:
            apps["730"] = {}
        apps["730"]["LaunchOptions"] = opts

        with open(path, "w", encoding="utf-8") as f:
            vdf.dump(data, f, pretty=True)

        print("cs2: updated LaunchOptions in localconfig.vdf")
    except Exception as e:
        print("cs2: failed to update localconfig.vdf: " + str(e), file=sys.stderr)
        sys.exit(1)
  '';

  # ---------------------------------------------------------------------------
  # Hyprland integration scripts
  # ---------------------------------------------------------------------------

  # Python interpreter with evdev for the counter-strafe daemon.
  # The daemon reads physical keyboard events (evdev, no grab) and injects
  # the opposite strafe key via ydotool/uinput when a strafe key is released.
  # Using physical evdev for input and uinput for output breaks the feedback
  # loop — injected events never reach the evdev monitor.
  pythonEvdev = pkgs.python3.withPackages (ps: [ ps.evdev ]);

  cs2CounterStrafeScript = pkgs.writeText "cs2-counterstrafe.py" ''
    import asyncio
    import evdev
    import subprocess
    import sys
    import os

    KEY_A = evdev.ecodes.KEY_A   # evdev code 30
    KEY_D = evdev.ecodes.KEY_D   # evdev code 32
    FLAG   = "/tmp/cs2-active"

    # Virtual/software devices to exclude — they re-emit physical events and
    # would cause feedback loops with the ydotool injection.
    VIRTUAL_KEYWORDS = ["xremap", "ydotool", "ydotoold", "virtual", "uinput"]

    def is_virtual(name):
        n = name.lower()
        return any(kw in n for kw in VIRTUAL_KEYWORDS)

    def active():
        return os.path.exists(FLAG)

    def inject(key):
        """Fire a brief key tap via ydotool (non-blocking)."""
        if active():
            subprocess.Popen(
                ["ydotool", "key", "--key-delay", "50",
                 str(key) + ":1", str(key) + ":0"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )

    async def monitor(device):
        try:
            async for event in device.async_read_loop():
                if event.type == evdev.ecodes.EV_KEY and event.value == 0:
                    if event.code == KEY_A:
                        inject(KEY_D)
                    elif event.code == KEY_D:
                        inject(KEY_A)
        except OSError:
            pass

    async def main():
        devices = []
        for path in evdev.list_devices():
            try:
                d    = evdev.InputDevice(path)
                if is_virtual(d.name):
                    continue
                caps = d.capabilities()
                keys = caps.get(evdev.ecodes.EV_KEY, [])
                if KEY_A in keys and KEY_D in keys and len(keys) > 50:
                    devices.append(d)
            except Exception:
                pass

        if not devices:
            print("cs2-counterstrafe: no keyboard found", file=sys.stderr)
            sys.exit(1)

        for d in devices:
            print("cs2-counterstrafe: monitoring " + d.name, file=sys.stderr)

        await asyncio.gather(*(monitor(d) for d in devices))

    asyncio.run(main())
  '';

  cs2CounterStrafeDaemon = pkgs.writeShellApplication {
    name = "cs2-counterstrafe-daemon";
    runtimeInputs = [ pythonEvdev pkgs.ydotool ];
    text = ''
      exec ${pythonEvdev}/bin/python3 ${cs2CounterStrafeScript}
    '';
  };

  cs2ModeStart = pkgs.writeShellApplication {
    name = "cs2-mode-start";
    runtimeInputs = [ pkgs.hyprland ];
    text = ''
      hyprctl dispatch submap CS2
      touch /tmp/cs2-active
    '';
  };

  cs2ModeStop = pkgs.writeShellApplication {
    name = "cs2-mode-stop";
    runtimeInputs = [ pkgs.hyprland ];
    text = ''
      hyprctl dispatch submap reset
      rm -f /tmp/cs2-active
    '';
  };

  # Monitors Hyprland IPC events to enter/exit the CS2 submap when the
  # CS2/gamescope window gains or loses focus.
  cs2FocusDaemon = pkgs.writeShellApplication {
    name = "cs2-focus-daemon";
    runtimeInputs = [
      pkgs.hyprland
      pkgs.socat
      pkgs.jq
      cs2ModeStart
      cs2ModeStop
    ];
    text = ''
      # Match cs2 by native class OR gamescope wrapping CS2 specifically.
      # Checking the title prevents matching other games running under gamescope.
      is_cs2_window() {
        local class="$1" title="$2"
        case "$class" in
          cs2|cs2.*) return 0 ;;
          gamescope*)
            case "$title" in
              *"Counter-Strike"*) return 0 ;;
            esac
            ;;
        esac
        return 1
      }

      CS2_FOCUSED=false

      # On startup: check whether CS2 is already the active window so we
      # enter CS2 mode immediately without waiting for the next focus event.
      active_json="$(hyprctl activewindow -j 2>/dev/null)"
      initial_class="$(echo "$active_json" | jq -r '.class // ""')"
      initial_title="$(echo "$active_json" | jq -r '.title // ""')"
      if is_cs2_window "$initial_class" "$initial_title"; then
        cs2-mode-start
        CS2_FOCUSED=true
      fi

      # Use process substitution so the while loop runs in the current shell,
      # not a subshell — CS2_FOCUSED changes persist across iterations.
      while read -r line; do
        case "$line" in
          activewindow*)
            # Event format: activewindow>>CLASS,TITLE
            payload="$(echo "$line" | awk -F '>>' '{print $2}')"
            class="$(echo "$payload" | awk -F ',' '{print $1}')"
            title="$(echo "$payload" | cut -d',' -f2-)"
            if is_cs2_window "$class" "$title"; then
              if [ "$CS2_FOCUSED" = "false" ]; then
                cs2-mode-start
                CS2_FOCUSED=true
              fi
            else
              if [ "$CS2_FOCUSED" = "true" ]; then
                cs2-mode-stop
                CS2_FOCUSED=false
              fi
            fi
            ;;
          closewindow*)
            if [ "$CS2_FOCUSED" = "true" ]; then
              if ! hyprctl clients -j | \
                   jq -e '.[] | select(.class | test("^cs2$"; "i") or (.class | test("^gamescope"; "i")) and (.title | test("Counter-Strike"; "i")))' \
                   > /dev/null 2>&1; then
                cs2-mode-stop
                CS2_FOCUSED=false
              fi
            fi
            ;;
        esac
      done < <(socat -U - \
        UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock")
    '';
  };

  # ---------------------------------------------------------------------------
  # cs2_video.txt
  # ---------------------------------------------------------------------------

  v = cfg.video;
  videoAttrs = {
    "Version" = "16";
    "VendorID" = toString v.vendorId;
    "DeviceID" = toString v.deviceId;
    "setting.cpu_level" = toString v.cpu;
    "setting.gpu_mem_level" = toString v.gpuMem;
    "setting.gpu_level" = toString v.gpu;
    "setting.knowndevice" = "0";
    "setting.defaultres" = toString v.resolution.width;
    "setting.defaultresheight" = toString v.resolution.height;
    "setting.refreshrate_numerator" = "0";
    "setting.refreshrate_denominator" = "0";
    "setting.fullscreen" = if v.displayMode == "fullscreen" then "1" else "0";
    "setting.coop_fullscreen" = "1";
    "setting.nowindowborder" = if v.displayMode == "borderless" then "1" else "0";
    "setting.mat_vsync" = if v.vsync then "1" else "0";
    "setting.fullscreen_min_on_focus_loss" = "0";
    "setting.high_dpi" = "0";
    "Autoconfig" = "2";
    "setting.shaderquality" = toString v.quality.shader;
    "setting.r_texturefilteringquality" = toString v.quality.textureFiltering;
    "setting.msaa_samples" = toString v.quality.msaa;
    "setting.r_csgo_cmaa_enable" = "0";
    "setting.videocfg_shadow_quality" = toString v.quality.shadows;
    "setting.videocfg_dynamic_shadows" = toString v.quality.dynamicShadows;
    "setting.videocfg_texture_detail" = toString v.quality.texture;
    "setting.videocfg_particle_detail" = toString v.quality.particles;
    "setting.videocfg_ao_detail" = toString v.quality.ambientOcclusion;
    "setting.videocfg_hdr_detail" = toString v.quality.hdr;
    "setting.videocfg_fsr_detail" = toString v.quality.fsr;
    "setting.monitor_index" = "0";
    "setting.r_low_latency" = toString v.lowLatency;
    "setting.aspectratiomode" = "1";
  };
  videoFile = pkgs.writeText "cs2_video.txt" ''
    "video.cfg"
    {
    ${vdfAttrs videoAttrs}
    }
  '';

  # ---------------------------------------------------------------------------
  # cs2_user_convars_0_slot0.vcfg
  # ---------------------------------------------------------------------------

  ch = cfg.crosshair;
  crosshairConvars = {
    "cl_crosshairstyle" = toString ch.style;
    "cl_crosshaircolor" = toString ch.color;
    "cl_crosshaircolor_r" = toString ch.colorRgb.r;
    "cl_crosshaircolor_g" = toString ch.colorRgb.g;
    "cl_crosshaircolor_b" = toString ch.colorRgb.b;
    "cl_crosshairalpha" = toString ch.alpha;
    "cl_crosshairsize" = toString ch.size;
    "cl_crosshairthickness" = toString ch.thickness;
    "cl_crosshairgap" = toString ch.gap;
    "cl_crosshairdot" = if ch.dot then "true" else "false";
    "cl_crosshair_t" = if ch.tStyle then "true" else "false";
    "cl_crosshair_drawoutline" = if ch.outline then "true" else "false";
    "cl_crosshair_outlinethickness" = toString ch.outlineThickness;
    "cl_crosshair_recoil" = if ch.followRecoil then "true" else "false";
    "cl_crosshairgap_useweaponvalue" = "false";
    "cl_crosshairusealpha" = "true";
    "crosshair" = "true";
  };
  mouseConvars = {
    "sensitivity" = toString cfg.mouse.sensitivity;
    "zoom_sensitivity_ratio" = toString cfg.mouse.zoomSensitivity;
    "sensitivity_y_scale" = "1.000000";
    "mouse_inverty" = if cfg.mouse.invertY then "true" else "false";
  };
  allConvars = crosshairConvars // mouseConvars // cfg.extraConvars;
  convarsFile = pkgs.writeText "cs2_user_convars_0_slot0.vcfg" ''
    "config"
    {
    	"convars"
    	{
    ${vdfAttrs allConvars}
    	}
    }
  '';

  # ---------------------------------------------------------------------------
  # cs2_user_keys_0_slot0.vcfg
  # ---------------------------------------------------------------------------

  bindsAttr = builtins.listToAttrs (
    map (b: {
      name = b.key;
      value = b.command;
    }) cfg.binds
  );
  keysFile = pkgs.writeText "cs2_user_keys_0_slot0.vcfg" ''
    "config"
    {
    	"bindings"
    	{
    ${vdfAttrs bindsAttr}
    	}
    }
  '';

  # ---------------------------------------------------------------------------
  # Userdata base path
  # ---------------------------------------------------------------------------

  userdataCfgPath = ".local/share/Steam/userdata/${cfg.steamId}/730/local/cfg";
in
{
  options = {
    modules = {
      gaming = {
        steam = {
          cs2 = {
            enable = lib.mkEnableOption "CS2 Steam desktop entry and settings" // {
              default = false;
            };

            steamId = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = ''
                Your Steam account ID — the directory name under ~/.local/share/Steam/userdata/.
                This is derived from your SteamID64 and is permanent per Steam account.
              '';
              example = "988490343";
            };

            # --- launch ---
            env = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              default = { };
              description = "Environment variables set before launching CS2.";
              example = {
                SDL_VIDEO_DRIVER = "wayland";
                SDL_AUDIO_DRIVER = "pipewire";
                MANGOHUD = "1";
                MANGOHUD_CONFIG = "fps_only=1";
                OBS_VKCAPTURE = "1";
              };
            };
            gamescope = {
              enable = lib.mkEnableOption "Wrap CS2 launch in gamescope" // {
                default = false;
              };
              args = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "Arguments passed to gamescope before --.";
                example = [
                  "-f"
                  "-W"
                  "3840"
                  "-H"
                  "2160"
                  "--force-grab-cursor"
                ];
              };
            };
            gameArgs = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Arguments passed to CS2 via steam -applaunch 730.";
              example = [
                "-vulkan"
                "-w"
                "3840"
                "-h"
                "2160"
                "-nojoy"
                "-novid"
              ];
            };

            # --- video (cs2_video.txt) ---
            video = {
              enable = lib.mkEnableOption "Manage cs2_video.txt" // {
                default = false;
              };
              vendorId = lib.mkOption {
                type = lib.types.int;
                default = 4318;
                description = "GPU vendor ID (4318 = NVIDIA / 0x10DE).";
              };
              deviceId = lib.mkOption {
                type = lib.types.int;
                default = 0;
                description = "GPU device ID (from lspci or the existing cs2_video.txt).";
              };
              cpu = lib.mkOption {
                type = lib.types.int;
                default = 3;
                description = "setting.cpu_level (0–3).";
              };
              gpu = lib.mkOption {
                type = lib.types.int;
                default = 3;
                description = "setting.gpu_level (0–3).";
              };
              gpuMem = lib.mkOption {
                type = lib.types.int;
                default = 3;
                description = "setting.gpu_mem_level (0–3).";
              };
              resolution = {
                width = lib.mkOption {
                  type = lib.types.int;
                  default = 1920;
                };
                height = lib.mkOption {
                  type = lib.types.int;
                  default = 1080;
                };
              };
              displayMode = lib.mkOption {
                type = lib.types.enum [
                  "windowed"
                  "borderless"
                  "fullscreen"
                ];
                default = "borderless";
                description = ''
                  windowed: no border, no fullscreen
                  borderless: fullscreen=0 + nowindowborder=1
                  fullscreen: exclusive fullscreen
                '';
              };
              vsync = lib.mkOption {
                type = lib.types.bool;
                default = false;
              };
              lowLatency = lib.mkOption {
                type = lib.types.int;
                default = 2;
                description = "setting.r_low_latency: 0=off, 1=on, 2=boost.";
              };
              quality = {
                shader = lib.mkOption {
                  type = lib.types.int;
                  default = 1;
                  description = "0=low, 1=high.";
                };
                textureFiltering = lib.mkOption {
                  type = lib.types.int;
                  default = 3;
                  description = "0–3 (anisotropic level).";
                };
                msaa = lib.mkOption {
                  type = lib.types.int;
                  default = 0;
                  description = "MSAA samples: 0, 2, 4, or 8.";
                };
                texture = lib.mkOption {
                  type = lib.types.int;
                  default = 2;
                  description = "Texture detail: 0–3.";
                };
                shadows = lib.mkOption {
                  type = lib.types.int;
                  default = 2;
                  description = "Shadow quality: 0–2.";
                };
                dynamicShadows = lib.mkOption {
                  type = lib.types.int;
                  default = 1;
                  description = "0=off, 1=on.";
                };
                particles = lib.mkOption {
                  type = lib.types.int;
                  default = 2;
                  description = "Particle detail: 0–2.";
                };
                ambientOcclusion = lib.mkOption {
                  type = lib.types.int;
                  default = 0;
                  description = "AO detail: 0=off, 1–2.";
                };
                hdr = lib.mkOption {
                  type = lib.types.int;
                  default = -1;
                  description = "HDR: -1=off, 0–2.";
                };
                fsr = lib.mkOption {
                  type = lib.types.int;
                  default = 0;
                  description = "FSR upscaling: 0=off.";
                };
              };
            };

            # --- crosshair (cs2_user_convars) ---
            crosshair = {
              style = lib.mkOption {
                type = lib.types.int;
                default = 5;
                description = "cl_crosshairstyle: 0=dynamic, 1=default, 2=classic, 3=classic-dynamic, 4=static, 5=static-custom.";
              };
              color = lib.mkOption {
                type = lib.types.int;
                default = 5;
                description = "cl_crosshaircolor: 0=red, 1=green, 2=yellow, 3=blue, 4=cyan, 5=custom.";
              };
              colorRgb = {
                r = lib.mkOption {
                  type = lib.types.int;
                  default = 0;
                };
                g = lib.mkOption {
                  type = lib.types.int;
                  default = 255;
                };
                b = lib.mkOption {
                  type = lib.types.int;
                  default = 0;
                };
              };
              alpha = lib.mkOption {
                type = lib.types.int;
                default = 200;
                description = "cl_crosshairalpha (0–255).";
              };
              size = lib.mkOption {
                type = lib.types.float;
                default = 1.5;
                description = "cl_crosshairsize.";
              };
              thickness = lib.mkOption {
                type = lib.types.float;
                default = 0.5;
                description = "cl_crosshairthickness.";
              };
              gap = lib.mkOption {
                type = lib.types.float;
                default = -5.0;
                description = "cl_crosshairgap.";
              };
              dot = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "cl_crosshairdot.";
              };
              tStyle = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "cl_crosshair_t (T-shape, removes top line).";
              };
              outline = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "cl_crosshair_drawoutline.";
              };
              outlineThickness = lib.mkOption {
                type = lib.types.float;
                default = 1.0;
                description = "cl_crosshair_outlinethickness.";
              };
              followRecoil = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "cl_crosshair_recoil.";
              };
            };

            # --- mouse (cs2_user_convars) ---
            mouse = {
              sensitivity = lib.mkOption {
                type = lib.types.float;
                default = 1.0;
                description = "sensitivity.";
              };
              zoomSensitivity = lib.mkOption {
                type = lib.types.float;
                default = 1.0;
                description = "zoom_sensitivity_ratio.";
              };
              invertY = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "mouse_inverty.";
              };
            };

            # --- binds (cs2_user_keys_0_slot0.vcfg) ---
            binds = lib.mkOption {
              type = lib.types.listOf (
                lib.types.submodule {
                  options = {
                    key = lib.mkOption { type = lib.types.str; };
                    command = lib.mkOption { type = lib.types.str; };
                  };
                }
              );
              default = [ ];
              description = "Keybinds written to cs2_user_keys_0_slot0.vcfg.";
              example = [
                {
                  key = "MOUSE1";
                  command = "+attack";
                }
                {
                  key = "MWHEELDOWN";
                  command = "+jump";
                }
                {
                  key = "SPACE";
                  command = "<unbound>";
                }
              ];
            };

            # --- extra convars (merged into cs2_user_convars) ---
            extraConvars = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              default = { };
              description = "Any additional convars merged into cs2_user_convars_0_slot0.vcfg.";
              example = {
                "con_enable" = "true";
                "cl_showloadout" = "true";
              };
            };

            # --- Hyprland integration ---
            hyprland = {
              enable = lib.mkEnableOption "CS2 Hyprland integration" // {
                default = false;
              };
            };
          };
        };
      };
    };
  };

  config =
    lib.mkIf (config.modules.gaming.enable && config.modules.gaming.steam.enable && cfg.enable)
      {
        # ydotool: needed for counter-strafe key injection via uinput.
        programs.ydotool.enable = lib.mkIf hcfg.enable (lib.mkDefault true);

        # User must be in the ydotool group (uinput access) and input group (evdev read).
        users.users.${config.modules.users.user} = lib.mkIf hcfg.enable {
          extraGroups = [
            config.programs.ydotool.group
            "input"
          ];
        };

        home-manager = lib.mkIf config.modules.home-manager.enable {
          users = {
            ${config.modules.users.user} = {
              xdg = {
                desktopEntries = {
                  cs2 = {
                    name = "Counter-Strike 2";
                    comment = "CS2 via Steam";
                    # Steam uses the LaunchOptions stored in localconfig.vdf (set via activation).
                    # This correctly wraps CS2 (not Steam) in gamescope via %command%.
                    exec = "steam -applaunch 730";
                    icon = "steam_icon_730";
                    categories = [ "Game" ];
                    settings = {
                      StartupWMClass = "cs2";
                    };
                  };
                };
              };

              home = {
                activation = lib.mkIf (cfg.steamId != "") {
                  cs2Settings = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                    cfgDir="$HOME/${userdataCfgPath}"
                    if [ -d "$cfgDir" ]; then
                      ${lib.optionalString cfg.video.enable ''
                        run install -m 644 ${videoFile} "$cfgDir/cs2_video.txt"
                      ''}
                      run install -m 644 ${convarsFile} "$cfgDir/cs2_user_convars_0_slot0.vcfg"
                      run install -m 644 ${keysFile} "$cfgDir/cs2_user_keys_0_slot0.vcfg"
                    else
                      echo "cs2: userdata cfg dir not found, skipping settings sync (CS2 not installed?)"
                    fi

                    # Update localconfig.vdf so Steam uses gamescope (%command%) as launch options.
                    # This wraps the CS2 executable — not Steam — regardless of whether Steam is
                    # already running when the desktop entry is clicked.
                    localcfg="$HOME/.local/share/Steam/userdata/${cfg.steamId}/config/localconfig.vdf"
                    if [ -f "$localcfg" ]; then
                      export CS2_LAUNCH_OPTS="${launchOptions}"
                      $DRY_RUN_CMD ${python}/bin/python3 ${updateLocalconfigScript} "$localcfg"
                    else
                      echo "cs2: localconfig.vdf not found, skipping launch options update (Steam not set up?)"
                    fi
                  '';
                };
              };

              # ---------------------------------------------------------------
              # Hyprland integration (focus tracking + counter-strafing)
              # ---------------------------------------------------------------
              systemd.user.services = lib.mkIf hcfg.enable {
                # Watches Hyprland IPC: enters/exits the CS2 submap when the
                # CS2/gamescope window is focused.
                cs2-focus-daemon = {
                  Unit = {
                    Description = "CS2 Hyprland focus tracking daemon";
                    After = [ "graphical-session.target" ];
                    PartOf = [ "graphical-session.target" ];
                  };
                  Service = {
                    ExecStart = "${cs2FocusDaemon}/bin/cs2-focus-daemon";
                    Restart = "on-failure";
                    RestartSec = "2s";
                  };
                  Install.WantedBy = [ "graphical-session.target" ];
                };

                # Reads physical keyboard evdev events; on A/D release injects
                # the opposite strafe key via ydotool/uinput for counter-strafing.
                # Only injects while /tmp/cs2-active exists (set by mode scripts).
                cs2-counterstrafe-daemon = {
                  Unit = {
                    Description = "CS2 counter-strafe daemon";
                    After = [ "graphical-session.target" ];
                    PartOf = [ "graphical-session.target" ];
                  };
                  Service = {
                    ExecStart = "${cs2CounterStrafeDaemon}/bin/cs2-counterstrafe-daemon";
                    Restart = "on-failure";
                    RestartSec = "2s";
                  };
                  Install.WantedBy = [ "graphical-session.target" ];
                };
              };

              wayland.windowManager.hyprland.extraConfig =
                lib.optionalString hcfg.enable ''
                  # CS2 submap — entered when the CS2/gamescope window is focused.
                  # Intercepts ESCAPE so that caps_lock (remapped to escape via xkb)
                  # does not trigger in-game actions.
                  # Counter-strafing is handled by the evdev daemon, not Hyprland binds,
                  # to avoid the feedback loop of injected keys re-triggering binds.
                  submap = CS2
                  bind = , ESCAPE, exec, true
                  submap = reset
                '';
            };
          };
        };
      };
}
