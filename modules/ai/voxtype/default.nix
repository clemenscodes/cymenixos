{
  inputs,
  pkgs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.ai;
  inherit (config.modules.users) user;
  voxtype = pkgs.voxtype-vulkan;
in {
  options = {
    modules = {
      ai = {
        voxtype = {
          enable = lib.mkEnableOption "Enable voxtype speech to text";
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.voxtype.enable) {
    home-manager = {
      users = {
        ${user} = {
          imports = [inputs.voxtype.homeManagerModules.default];
          wayland = {
            windowManager = {
              hyprland = {
                extraConfig = ''
                  bind = $mod, T, exec, ${voxtype}/bin/voxtype record toggle --clipboard
                '';
              };
            };
          };
          programs = {
            voxtype = {
              inherit (cfg.voxtype) enable;
              package = voxtype;
              service = {
                inherit (cfg.voxtype) enable;
              };
              engine = "whisper";
              model = {
                name = "large-v3-turbo";
              };
              settings = {
                meeting = {
                  enabled = true;
                  mic_device = "default";
                  loopback_device = "auto";
                  echo_cancel = "auto";
                };
                state_file = "auto";
                status = {
                  icon_theme = "emoji";
                };
                hotkey = {
                  enabled = false;
                };
                whisper = {
                  language = "en";
                  translate = false;
                };
                text = {
                  spoken_punctuation = true;
                };
                output = {
                  notification = {
                    on_recording_start = false;
                    on_recording_stop = false;
                    on_transcription = false;
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
