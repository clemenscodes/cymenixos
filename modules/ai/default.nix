{
  inputs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules;
  inherit (config.modules.boot.impermanence) persistPath;
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      cudaSupport = true;
      allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          "lmstudio"
          "claude-code"
          "nvidia-x11"
          "nvidia-settings"
          "nvidia-persistenced"
          "cuda-merged"
          "cuda_cuobjdump"
          "cuda_gdb"
          "cuda_nvcc"
          "cuda_nvdisasm"
          "cuda_nvprune"
          "cuda_cccl"
          "cuda_cudart"
          "cuda_cupti"
          "cuda_cuxxfilt"
          "cuda_nvml_dev"
          "cuda_nvrtc"
          "cuda_nvtx"
          "cuda_profiler_api"
          "cuda_sanitizer_api"
          "libcublas"
          "libcufft"
          "libcurand"
          "libcusolver"
          "libnvjitlink"
          "libcusparse"
          "libnpp"
          "cudnn"
        ];
    };
  };
in {
  options.modules.ai.enable = lib.mkEnableOption "Enable AI support";
  config = lib.mkIf (cfg.enable && cfg.ai.enable) {
    environment.persistence."${persistPath}" = lib.mkIf (config.modules.boot.enable) {
      directories = ["/var/lib/ai"];
    };
    environment.systemPackages = with pkgs; [
      lmstudio
      claude-code
    ];
    users.users.ollama = {
      isSystemUser = true;
      group = "ollama";
      home = "/var/lib/ai/ollama";
      createHome = false;
    };
    users.groups.ollama = {};
    systemd.tmpfiles.rules = [
      "d /var/lib/ai 0755 root root -"
      "d /var/lib/ai/ollama 0750 ollama ollama -"
      "d /var/lib/ai/ollama/models 0750 ollama ollama -"
    ];
    services.ollama = {
      enable = true;
      openFirewall = true;
      syncModels = true;
      package = pkgs.ollama-cuda;
      user = "ollama";
      group = "ollama";
      home = "/var/lib/ai/ollama";
      models = "/var/lib/ai/ollama/models";
      loadModels = ["qwen3-coder-next:q4_K_M" "qwen3-coder:30b"];
    };
    systemd.services.ollama.serviceConfig = {
      StateDirectory = lib.mkForce [];
      ProtectSystem = lib.mkForce "full";
      ReadWritePaths = lib.mkForce [
        "/var/lib/ai"
        "/var/lib/ai/ollama"
        "/var/lib/ai/ollama/models"
      ];
    };
    home-manager = {
      users = {
        ${config.modules.users.user} = {
          imports = [inputs.peon-ping.homeManagerModules.default];
          home.persistence = lib.mkIf (config.modules.boot.enable) {
            "${persistPath}" = {
              directories = [".openpeon"];
            };
          };
          programs.peon-ping = {
            enable = true;
            package = inputs.peon-ping.packages.${pkgs.system}.default;
            settings = {
              default_pack = "peasant";
              volume = 0.7;
              enabled = true;
              desktop_notifications = true;
              enableZshIntegration = true;
              categories = {
                "session.start" = true;
                "task.complete" = true;
                "task.error" = true;
                "input.required" = true;
                "resource.limit" = true;
                "user.spam" = true;
              };
            };
          };
        };
      };
    };
  };
}
