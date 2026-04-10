{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.gaming.steam.cs2;
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

  # Env vars are prepended to launchOptions so only CS2/gamescope inherit them.
  launchOptions = let
    envStr = lib.concatStringsSep " " (lib.mapAttrsToList (k: v: "${k}=${v}") cfg.env);
    baseCmd =
      if cfg.gamescope.enable
      then "gamescope ${lib.concatStringsSep " " cfg.gamescope.args} -- %command%"
      else "%command%";
    commandStr =
      if cfg.commandWrapper != ""
      then "${cfg.commandWrapper} ${baseCmd}"
      else baseCmd;
    gameArgsStr = lib.concatStringsSep " " cfg.gameArgs;
  in
    lib.concatStringsSep " " (
      lib.filter (s: s != "") [
        envStr
        commandStr
        gameArgsStr
      ]
    );

  # Python script that patches localconfig.vdf with the CS2 launch options.
  # Reads the launch options string from $CS2_LAUNCH_OPTS to avoid shell quoting issues.
  python = pkgs.python3.withPackages (ps: [ps.vdf]);
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
        apps["730"]["OverlayAppEnable"] = "0"

        with open(path, "w", encoding="utf-8") as f:
            vdf.dump(data, f, pretty=True)

        print("cs2: updated LaunchOptions and disabled overlay in localconfig.vdf")
    except Exception as e:
        print("cs2: failed to update localconfig.vdf: " + str(e), file=sys.stderr)
        sys.exit(1)
  '';

  # ---------------------------------------------------------------------------
  # kill-cs2: force-kill CS2 and all Steam subprocess wrappers
  #
  # Kills the SteamLaunch reaper (keyed by AppId 730), pressure-vessel wrapper,
  # and the cs2 process itself so Steam clears the "game running" lock and
  # allows a clean restart without restarting Steam.
  # ---------------------------------------------------------------------------

  killCs2 = pkgs.writeShellScriptBin "kill-cs2" ''
    echo "Killing CS2 process tree..."
    ${pkgs.procps}/bin/pkill -9 -f 'cs2' || true
    ${pkgs.procps}/bin/pkill -9 -f 'SteamLaunch.*AppId=730' || true
    ${pkgs.procps}/bin/pkill -9 -f 'pressure-vessel' || true
    ${pkgs.procps}/bin/pkill -9 -f 'steam-runtime-launcher-service' || true
    sleep 1
    if ${pkgs.procps}/bin/pgrep -f 'cs2' > /dev/null 2>&1; then
      echo "WARNING: cs2 still running:"
      ${pkgs.procps}/bin/pgrep -a -f 'cs2'
    else
      echo "CS2 fully dead. Steam should let you restart now."
    fi
  '';

  # cs2-toggle: launch CS2 if not running, kill it if it is.
  # Env vars reach CS2 via home.sessionVariables (inherited by Steam at login).
  # wrapper, game args) — safe to do even when Steam is running since these rarely
  # localconfig.vdf is patched here only for structural launch options (gamescope
  # change and take effect on the next Steam restart.
  toggleCs2 = pkgs.writeShellScriptBin "cs2-toggle" ''
    if ${pkgs.procps}/bin/pgrep -x 'cs2' > /dev/null 2>&1; then
      ${killCs2}/bin/kill-cs2
      ${pkgs.hyprland}/bin/hyprctl dispatch submap reset
    else
      localcfg="$HOME/.local/share/Steam/userdata/${cfg.steamId}/config/localconfig.vdf"
      if [ -f "$localcfg" ]; then
        export CS2_LAUNCH_OPTS="${launchOptions}"
        ${python}/bin/python3 ${updateLocalconfigScript} "$localcfg"
      fi
      nohup steam -applaunch 730 >/dev/null 2>&1 &
      ${pkgs.hyprland}/bin/hyprctl dispatch submap cs2
    fi
  '';

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
    "setting.fullscreen" =
      if v.displayMode == "fullscreen"
      then "1"
      else "0";
    "setting.coop_fullscreen" = "1";
    "setting.nowindowborder" =
      if v.displayMode == "borderless"
      then "1"
      else "0";
    "setting.mat_vsync" =
      if v.vsync
      then "1"
      else "0";
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
    "cl_crosshairdot" =
      if ch.dot
      then "true"
      else "false";
    "cl_crosshair_t" =
      if ch.tStyle
      then "true"
      else "false";
    "cl_crosshair_drawoutline" =
      if ch.outline
      then "true"
      else "false";
    "cl_crosshair_outlinethickness" = toString ch.outlineThickness;
    "cl_crosshair_recoil" =
      if ch.followRecoil
      then "true"
      else "false";
    "cl_crosshairgap_useweaponvalue" = "false";
    "cl_crosshairusealpha" = "true";
    "crosshair" = "true";
  };
  mouseConvars = {
    "sensitivity" = toString cfg.mouse.sensitivity;
    "zoom_sensitivity_ratio" = toString cfg.mouse.zoomSensitivity;
    "sensitivity_y_scale" = "1.000000";
    "mouse_inverty" =
      if cfg.mouse.invertY
      then "true"
      else "false";
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
  # autoexec.cfg  — plain console commands run by CS2 on startup
  # ---------------------------------------------------------------------------

  # ---------------------------------------------------------------------------
  # nulls.cfg  — null-movement aliases (last-pressed WASD key wins)
  # ---------------------------------------------------------------------------

  nullsFile = pkgs.writeText "nulls.cfg" ''
    alias"+a""rightleft -1 0 0; alias +d ad"
    alias"a1""rightleft -1 0 0; alias +d ad"
    alias"ad""rightleft 1 0 0; alias -d add; alias -a ada"
    alias"-a""rightleft 0 0 0; alias +d d1; alias -d d2; alias -a a2; alias +a a1"
    alias"a2""rightleft 0 0 0; alias +d d1; alias -d d2; alias -a a2; alias +a a1"
    alias"+d""rightleft 1 0 0; alias +a da"
    alias"d1""rightleft 1 0 0; alias +a da"
    alias"da""rightleft -1 0 0; alias -a ada; alias -d add"
    alias"-d""rightleft 0 0 0; alias +a a1; alias -a a2; alias -d d2; alias +d d1"
    alias"d2""rightleft 0 0 0; alias +a a1; alias -a a2; alias -d d2; alias +d d1"
    alias"add""rightleft -1 0 0; alias +d ad; alias -a a2; alias -d d2"
    alias"ada""rightleft 1 0 0; alias +a da; alias -d d2; alias -a a2"

    alias"+w""forwardback 1 0 0;alias +s ws"
    alias"w1""forwardback 1 0 0;alias +s ws"
    alias"ws""forwardback -1 0 0;alias -s wss;alias -w wsw"
    alias"-w""forwardback 0 0 0;alias +s s1;alias -s s2;alias -w w2;alias +w w1"
    alias"w2""forwardback 0 0 0;alias +s s1;alias -s s2;alias -w w2;alias +w w1"
    alias"+s""forwardback -1 0 0;alias +w sw"
    alias"s1""forwardback -1 0 0;alias +w sw"
    alias"sw""forwardback 1 0 0;alias -w wsw;alias -s wss"
    alias"-s""forwardback 0 0 0;alias +w w1;alias -w w2;alias -s s2;alias +s s1"
    alias"s2""forwardback 0 0 0;alias +w w1;alias -w w2;alias -s s2;alias +s s1"
    alias"wss""forwardback 1 0 0;alias +s ws;alias -w w2;alias -s s2"
    alias"wsw""forwardback -1 0 0;alias +w sw;alias -s s2;alias -w w2"
  '';

  # Null-movement bootstrap lines prepended to autoexec when nulls.enable is true.
  # exec nulls must come first so the +w/+a/+s/+d aliases exist before being bound.
  nullsAutoexecLines = lib.optionals cfg.nulls.enable [
    ''exec nulls''
    ''bind "w" "+w"; bind "a" "+a"; bind "s" "+s"; bind "d" "+d"''
  ];

  autoexecFile = pkgs.writeText "autoexec.cfg" (
    lib.concatStringsSep "\n" (nullsAutoexecLines ++ cfg.autoexec) + "\n" + "host_writeconfig"
  );

  # ---------------------------------------------------------------------------
  # cs2_user_keys_0_slot0.vcfg
  # ---------------------------------------------------------------------------

  bindsAttr = builtins.listToAttrs (
    map (b: {
      name = b.key;
      value = b.command;
    })
    cfg.binds
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
in {
  options = {
    modules = {
      gaming = {
        steam = {
          cs2 = {
            enable =
              lib.mkEnableOption "CS2 Steam desktop entry and settings"
              // {
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
              default = {};
              description = "Environment variables set before launching CS2.";
              example = {
                SDL_VIDEO_DRIVER = "wayland";
                SDL_AUDIO_DRIVER = "pipewire";
                MANGOHUD = "1";
                MANGOHUD_CONFIG = "fps_only=1";
                OBS_VKCAPTURE = "1";
                XKB_DEFAULT_MODEL = "pc105";
                XKB_DEFAULT_LAYOUT = "de";
              };
            };
            gamescope = {
              enable =
                lib.mkEnableOption "Wrap CS2 launch in gamescope"
                // {
                  default = false;
                };
              args = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [];
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
            commandWrapper = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "Command prepended before %command% in Steam launch options (e.g. 'taskset -c 0-7,16-23').";
              example = "taskset -c 0-7,16-23";
            };
            gameArgs = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
              description = "Arguments passed to CS2 via steam -applaunch 730.";
              example = [
                "-vulkan"
                "-w"
                "3840"
                "-h"
                "2160"
                "-nojoy"
                "-sdlaudiodriver"
                "pipewire"
                "+fps_max"
                "0"
                "-forcenovsync"
                "-refresh 240"
              ];
            };

            # --- video (cs2_video.txt) ---
            video = {
              enable =
                lib.mkEnableOption "Manage cs2_video.txt"
                // {
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
                    key = lib.mkOption {type = lib.types.str;};
                    command = lib.mkOption {type = lib.types.str;};
                  };
                }
              );
              default = [];
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
              default = {};
              description = "Any additional convars merged into cs2_user_convars_0_slot0.vcfg.";
              example = {
                "con_enable" = "true";
                "cl_showloadout" = "true";
              };
            };

            # --- nulls movement ---
            nulls = {
              enable =
                lib.mkEnableOption "Null-movement (last-pressed WASD key wins via rightleft/forwardback)"
                // {
                  default = false;
                };
            };

            # --- autoexec (written to autoexec.cfg, executed by CS2 on startup) ---
            autoexec = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
              description = "Console commands written to autoexec.cfg and executed by CS2 on startup.";
              example = [
                "gameui_preventescapetoshow"
                "con_enable 1"
              ];
            };
          };
        };
      };
    };
  };

  config =
    lib.mkIf (config.modules.gaming.enable && config.modules.gaming.steam.enable && cfg.enable)
    {
      environment.systemPackages = [
        killCs2
        toggleCs2
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
                  exec = "${toggleCs2}/bin/cs2-toggle";
                  icon = "steam_icon_730";
                  categories = ["Game"];
                  settings = {
                    StartupWMClass = "cs2";
                  };
                };
              };
            };

            home = {
              activation = lib.mkIf (cfg.steamId != "") {
                cs2Settings = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
                  cfgDir="$HOME/${userdataCfgPath}"
                  if [ -d "$cfgDir" ]; then
                    ${lib.optionalString cfg.video.enable ''
                    run install -m 644 ${videoFile} "$cfgDir/cs2_video.txt"
                  ''}
                    run install -m 644 ${convarsFile} "$cfgDir/cs2_user_convars_0_slot0.vcfg"
                    run install -m 644 ${keysFile} "$cfgDir/cs2_user_keys_0_slot0.vcfg"
                    ${lib.optionalString (cfg.autoexec != [] || cfg.nulls.enable) ''
                    gameCfgDir="$HOME/.local/share/Steam/steamapps/common/Counter-Strike Global Offensive/game/csgo/cfg"
                    if [ -d "$gameCfgDir" ]; then
                      ${lib.optionalString (cfg.autoexec != [] || cfg.nulls.enable) ''
                      run install -m 644 ${autoexecFile} "$gameCfgDir/autoexec.cfg"
                    ''}
                      ${lib.optionalString cfg.nulls.enable ''
                      run install -m 644 ${nullsFile} "$gameCfgDir/nulls.cfg"
                    ''}
                    else
                      echo "cs2: game cfg dir not found, skipping cfg files (CS2 not installed?)"
                    fi
                  ''}
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
          };
        };
      };
    };
}
