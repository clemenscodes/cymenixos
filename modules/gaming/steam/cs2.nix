{
  inputs,
  pkgs,
  lib,
  ...
}:
{ config, ... }:
let
  cfg = config.modules.gaming.steam.cs2;

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # VDF key-value line: two tabs between key and value (matches CS2's own format)
  vdfLine = k: v: "\t\t\"${k}\"\t\t\"${v}\"";

  # Generate a VDF convars/bindings block from an attrset
  vdfAttrs = attrs: lib.concatStringsSep "\n" (lib.mapAttrsToList vdfLine attrs);

  # ---------------------------------------------------------------------------
  # Launch script
  # ---------------------------------------------------------------------------

  envExports = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (k: v: "export ${k}=${lib.escapeShellArg v}") cfg.env
  );
  gamescopePrefix = lib.optionalString cfg.gamescope.enable "gamescope ${lib.concatStringsSep " " cfg.gamescope.args} -- ";
  gameArgsStr = lib.concatStringsSep " " cfg.gameArgs;
  launchScript = pkgs.writeShellScript "cs2-launch" ''
    ${envExports}
    exec ${gamescopePrefix}steam -applaunch 730 ${gameArgsStr}
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
          };
        };
      };
    };
  };

  config =
    lib.mkIf (config.modules.gaming.enable && config.modules.gaming.steam.enable && cfg.enable)
      {
        home-manager = lib.mkIf config.modules.home-manager.enable {
          users = {
            ${config.modules.users.user} = {
              xdg = {
                desktopEntries = {
                  cs2 = {
                    name = "Counter-Strike 2";
                    comment = "CS2 via Steam";
                    exec = "${launchScript}";
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
                  '';
                };
              };
            };
          };
        };
      };
}
