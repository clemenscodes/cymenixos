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
  inherit (config.modules.boot.impermanence) persistPath;
  inherit (config.modules.users) user;

  cudaPkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      cudaSupport = true;
      allowUnfree = true;
    };
  };

  vibevoicePkg = cudaPkgs.callPackage ./package.nix {};

  vibevoiceEnv = cudaPkgs.python3.withPackages (_ps: [vibevoicePkg]);
in {
  options = {
    modules = {
      ai = {
        vibevoice = {
          enable = lib.mkEnableOption "Enable VibeVoice local TTS (7B)";
          model = lib.mkOption {
            type = lib.types.str;
            default = "vibevoice/VibeVoice-7B";
            description = "HuggingFace model ID to load";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 8020;
            description = "Port for the VibeVoice Gradio API";
          };
          openFirewall = lib.mkEnableOption "Open firewall for VibeVoice API port";
        };
      };
    };
  };

  config = lib.mkIf (cfg.enable && cfg.vibevoice.enable) {
    environment = {
      systemPackages = [vibevoiceEnv];
      # Only persist vibevoice's own subdirectory when ollama is not enabled.
      # When ollama is enabled it already persists the parent /var/lib/ai,
      # which covers /var/lib/ai/vibevoice — adding a nested bind-mount on
      # top of that would be redundant and can confuse impermanence.
      persistence = lib.mkIf (config.modules.boot.enable && !cfg.ollama.enable) {
        "${persistPath}" = {
          directories = ["/var/lib/ai/vibevoice"];
        };
      };
    };

    users = {
      users = {
        vibevoice = {
          isSystemUser = true;
          group = "vibevoice";
          home = "/var/lib/ai/vibevoice";
          createHome = false;
        };
      };
      groups = {
        vibevoice = {};
      };
    };

    systemd = {
      tmpfiles = {
        rules = [
          "d /var/lib/ai 0755 root root -"
          "d /var/lib/ai/vibevoice 0750 vibevoice vibevoice -"
          "d /var/lib/ai/vibevoice/cache 0750 vibevoice vibevoice -"
        ];
      };
      services = {
        vibevoice = {
          description = "VibeVoice TTS API server (7B)";
          wantedBy = ["multi-user.target"];
          after = ["network.target"];
          environment = {
            HF_HOME = "/var/lib/ai/vibevoice/cache";
            TRANSFORMERS_CACHE = "/var/lib/ai/vibevoice/cache";
            VIBEVOICE_MODEL = cfg.vibevoice.model;
          };
          serviceConfig = {
            User = "vibevoice";
            Group = "vibevoice";
            ExecStart = "${vibevoiceEnv}/bin/python -m vibevoice.server --model ${cfg.vibevoice.model} --port ${toString cfg.vibevoice.port}";
            Restart = "on-failure";
            RestartSec = 10;
            StateDirectory = lib.mkForce [];
            ProtectSystem = lib.mkForce "full";
            ReadWritePaths = lib.mkForce [
              "/var/lib/ai/vibevoice"
            ];
          };
        };
      };
    };

    networking = {
      firewall = lib.mkIf cfg.vibevoice.openFirewall {
        allowedTCPPorts = [cfg.vibevoice.port];
      };
    };
  };
}
