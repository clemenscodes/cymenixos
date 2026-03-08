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
  inherit (config.modules.boot.impermanence) persistPath;
  parakeetModel = import ./parakeet-model.nix {inherit pkgs lib;};
  voxtypePkg =
    if cfg.voxtype.parakeet
    then pkgs.voxtype-onnx
    else pkgs.voxtype-vulkan;
in {
  options = {
    modules = {
      ai = {
        voxtype = {
          enable = lib.mkEnableOption "Enable voxtype speech to text";
          parakeet = lib.mkEnableOption "Use Parakeet CUDA engine instead of Whisper";
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.voxtype.enable) {
    home-manager = {
      users = {
        ${user} = {
          imports = [inputs.voxtype.homeManagerModules.default];
          home = {
            persistence = lib.mkIf (config.modules.boot.enable) {
              "${persistPath}" = {
                directories = [".local/share/voxtype"];
              };
            };
          };
          wayland = {
            windowManager = {
              hyprland = {
                extraConfig = ''
                  bind = $mod, T, exec, ${voxtypePkg}/bin/voxtype record toggle --clipboard
                '';
              };
            };
          };
          programs = {
            voxtype = {
              inherit (cfg.voxtype) enable;
              package = voxtypePkg;
              service = {
                inherit (cfg.voxtype) enable;
              };
              engine =
                if cfg.voxtype.parakeet
                then "parakeet"
                else "whisper";
              model =
                if cfg.voxtype.parakeet
                then {path = "${parakeetModel}";}
                else {name = "large-v3-turbo";};
              settings =
                {
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
                }
                // lib.optionalAttrs (!cfg.voxtype.parakeet) {
                  whisper = {
                    language = "en";
                    translate = false;
                  };
                }
                // lib.optionalAttrs (cfg.voxtype.parakeet) {
                  parakeet = {
                    model_type = "tdt";
                    on_demand_loading = true;
                  };
                };
            };
          };
        };
      };
    };
  };
}
