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
      gamescopeStr = lib.optionalString cfg.gamescope.enable "gamescope ${lib.concatStringsSep " " cfg.gamescope.args} -- ";
      gameArgsStr = lib.concatStringsSep " " cfg.gameArgs;
    in
    lib.concatStringsSep " " (
      lib.filter (s: s != "") [
        envStr
        "${gamescopeStr}%command%"
        gameArgsStr
      ]
    );

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
  # Hyprland integration scripts (submap-based counter-strafing)
  # ---------------------------------------------------------------------------
  #
  # Flow:
  #   cs2-focus-daemon watches Hyprland IPC and dispatches to the CS2 submap
  #   whenever CS2 gains focus (and back to reset on any other window).
  #
  #   CS2 submap: A/D presses are intercepted.
  #     A press → switch to CS2_STRAFING_LEFT, inject A:1 (passes through in
  #               new submap since only bindr is present there)
  #     D press → symmetric
  #
  #   CS2_STRAFING_LEFT: only A release is intercepted (bindr).
  #     A release → switch to CS2_COUNTER_RIGHT, inject A:0, inject D:1 D:0
  #                 (D is unbound in CS2_COUNTER_RIGHT → passes through),
  #                 wait for echoes, return to CS2.
  #
  #   CS2_COUNTER_RIGHT / CS2_COUNTER_LEFT: empty submaps.  Injected counter-
  #   strafe keys arrive here where they are NOT bound, so they pass through
  #   to the game without triggering another counter-strafe.

  cs2FocusDaemon = pkgs.writeShellApplication {
    name = "cs2-focus-daemon";
    runtimeInputs = [
      pkgs.hyprland
      pkgs.socat
      pkgs.jq
    ];
    text = ''
      enter_cs2() { hyprctl dispatch submap CS2   >/dev/null 2>&1; }
      leave_cs2()  { hyprctl dispatch submap reset >/dev/null 2>&1; }

      is_cs2() {
        local class="$1" title="$2"
        [[ "$class" == "cs2" ]] || { [[ "$class" == gamescope* ]] && [[ "$title" == *"Counter-Strike"* ]]; }
      }

      # Check which window is focused right now (service may start mid-session)
      info=$(hyprctl activewindow -j 2>/dev/null || echo '{}')
      class=$(printf '%s' "$info" | jq -r '.class // ""')
      title=$(printf '%s' "$info" | jq -r '.title // ""')
      if is_cs2 "$class" "$title"; then
        enter_cs2
      else
        leave_cs2
      fi

      # React to every subsequent focus change via Hyprland IPC socket2
      while IFS= read -r line; do
        event="''${line%%>>*}"
        data="''${line#*>>}"
        if [[ "$event" == "activewindow" ]]; then
          class="''${data%%,*}"
          title="''${data#*,}"
          if is_cs2 "$class" "$title"; then
            enter_cs2
          else
            leave_cs2
          fi
        fi
      done < <(socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock")
    '';
  };

  cs2Log = "/tmp/cs2-strafe.log";

  # bindn passes the key through to the game AND marks it as bound so bindr fires on release.
  # These start scripts only log — no injection needed.
  cs2StrafeLeftStart = pkgs.writeShellApplication {
    name = "cs2-strafe-left-start";
    runtimeInputs = [ pkgs.hyprland ];
    text = ''
      echo "$(date +%T.%3N) [left-start]  A pressed (passing through to game)" >> ${cs2Log}
    '';
  };

  cs2StrafeRightStart = pkgs.writeShellApplication {
    name = "cs2-strafe-right-start";
    runtimeInputs = [ pkgs.hyprland ];
    text = ''
      echo "$(date +%T.%3N) [right-start] D pressed (passing through to game)" >> ${cs2Log}
    '';
  };

  # bindr intercepts the release (does NOT pass to game).
  # Sequence: keep direction held → press counter → release direction → release counter.
  # CS2_INJECT is empty so injected keys pass through without re-triggering CS2 binds.
  cs2StrafeLeftStop = pkgs.writeShellApplication {
    name = "cs2-strafe-left-stop";
    runtimeInputs = [ pkgs.hyprland pkgs.ydotool ];
    text = ''
      log() { echo "$(date +%T.%3N) [left-stop]  $*" >> ${cs2Log}; }
      log "A release intercepted — counter-strafe start"
      hyprctl dispatch submap CS2_INJECT >/dev/null
      log "inject A:1 (keep direction held)"
      ydotool key 30:1
      log "inject D:1 (press counter direction)"
      ydotool key 32:1
      log "inject A:0 (release direction)"
      ydotool key 30:0
      log "inject D:0 (release counter direction)"
      ydotool key 32:0
      hyprctl dispatch submap CS2 >/dev/null
      log "done — returned to CS2 submap"
    '';
  };

  cs2StrafeRightStop = pkgs.writeShellApplication {
    name = "cs2-strafe-right-stop";
    runtimeInputs = [ pkgs.hyprland pkgs.ydotool ];
    text = ''
      log() { echo "$(date +%T.%3N) [right-stop] $*" >> ${cs2Log}; }
      log "D release intercepted — counter-strafe start"
      hyprctl dispatch submap CS2_INJECT >/dev/null
      log "inject D:1 (keep direction held)"
      ydotool key 32:1
      log "inject A:1 (press counter direction)"
      ydotool key 30:1
      log "inject D:0 (release direction)"
      ydotool key 32:0
      log "inject A:0 (release counter direction)"
      ydotool key 30:0
      hyprctl dispatch submap CS2 >/dev/null
      log "done — returned to CS2 submap"
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

        # User must be in the ydotool group (uinput access for key injection).
        users.users.${config.modules.users.user} = lib.mkIf hcfg.enable {
          extraGroups = [ config.programs.ydotool.group ];
        };

        # Expose scripts in PATH so they can be run and tested manually.
        environment.systemPackages = lib.mkIf hcfg.enable [
          cs2FocusDaemon
          cs2StrafeLeftStart
          cs2StrafeLeftStop
          cs2StrafeRightStart
          cs2StrafeRightStop
        ];

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
              # Hyprland integration (submap-based counter-strafing)
              # ---------------------------------------------------------------
              systemd.user.services = lib.mkIf hcfg.enable {
                # Watches Hyprland IPC for window focus changes and dispatches
                # to the CS2 submap when CS2 is focused, reset otherwise.
                cs2-focus-daemon = {
                  Unit = {
                    Description = "CS2 Hyprland focus daemon";
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
              };

              wayland.windowManager.hyprland.extraConfig = lib.mkIf hcfg.enable ''
                # CS2 submap — entered automatically by cs2-focus-daemon when CS2 gains focus.
                #
                # bindn = non-consuming press: key passes through to game AND marks it for bindr.
                # bindr = consuming release:   key release intercepted, NOT forwarded to game.
                #
                # On release the stop script injects: A:1 → D:1 → A:0 → D:0
                # (keep held → press counter → release dir → release counter).
                # All injections happen in CS2_INJECT where no bind consumes them,
                # preventing echo loops when returning to CS2.
                submap = CS2
                bind  = ALT, W, submap, reset
                bindn = , A, exec, ${cs2StrafeLeftStart}/bin/cs2-strafe-left-start
                bindr = , A, exec, ${cs2StrafeLeftStop}/bin/cs2-strafe-left-stop
                bindn = , D, exec, ${cs2StrafeRightStart}/bin/cs2-strafe-right-start
                bindr = , D, exec, ${cs2StrafeRightStop}/bin/cs2-strafe-right-stop

                # Empty — injected keys land here, unbound, and pass through to the game.
                submap = CS2_INJECT
                bind = ALT, W, submap, reset

                submap = reset
              '';
            };
          };
        };
      };
}
