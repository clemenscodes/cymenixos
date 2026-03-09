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
  meeting-toggle = pkgs.callPackage ./voxtype-meeting-toggle.nix {voxtype = voxtypePkg;};
  meeting-pause-toggle = pkgs.callPackage ./voxtype-meeting-pause-toggle.nix {voxtype = voxtypePkg;};
  meeting-export = pkgs.callPackage ./voxtype-meeting-export.nix {voxtype = voxtypePkg;};
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
            packages = [meeting-toggle meeting-pause-toggle meeting-export];
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
                  # Recording
                  bind = $mod, T, exec, ${voxtypePkg}/bin/voxtype record toggle --clipboard
                  bind = $mod SHIFT, T, exec, ${voxtypePkg}/bin/voxtype record toggle --clipboard --profile teams
                  bind = $mod ALT, T, exec, ${voxtypePkg}/bin/voxtype record toggle --clipboard --profile email
                  bind = $mod CTRL, T, exec, ${voxtypePkg}/bin/voxtype record cancel
                  # Meetings
                  bind = $mod, I, exec, ${meeting-toggle}/bin/voxtype-meeting-toggle
                  bind = $mod SHIFT, I, exec, ${meeting-pause-toggle}/bin/voxtype-meeting-pause-toggle
                  bind = $mod ALT, I, exec, ${meeting-export}/bin/voxtype-meeting-export
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
                    chunk_duration_secs = 30;
                    storage_path = "auto";
                    max_duration_mins = 180;
                    retain_audio = false;
                    audio = {
                      mic_device = "default";
                      loopback_device = "auto";
                      echo_cancel = "auto";
                    };
                  };
                  state_file = "auto";
                  status = {
                    icon_theme = "emoji";
                  };
                  hotkey = {
                    enabled = false;
                  };
                  profiles = lib.mkIf (cfg.ollama.enable) {
                    teams = {
                      post_process_command = "${config.services.ollama.package}/bin/ollama run llama3.2:1b 'Clean up this technical transcription for Microsoft Teams. Keep it casual and concise. Output only the cleaned text'";
                    };
                    email = {
                      post_process_command = "${config.services.ollama.package}/bin/ollama run llama3.2:1b 'Clean up this technical transcription to a professional email text. Output only the cleaned text'";
                    };
                  };
                  text = {
                    spoken_punctuation = true;
                  };
                  vad = {
                    enabled = true;
                    backend = "auto";
                    threshold = 0.5;
                    min_speech_duration_ms = 100;
                  };
                  output = {
                    mode = "clipboard";
                    post_process = lib.mkIf (cfg.ollama.enable) {
                      command = "${config.services.ollama.package}/bin/ollama run llama3.2:1b 'Clean up this technical transcription to great prompt for Claude Code. Fix grammar and remove filler words and replace technical punctuation with the symbols. Output only the cleaned text'";
                      timeout_ms = 30000;
                    };
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
