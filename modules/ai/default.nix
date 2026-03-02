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
      allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          "lmstudio"
          "claude-code"
        ];
    };
  };
in {
  options = {
    modules = {
      ai = {
        enable = lib.mkEnableOption "Enable AI support" // {default = false;};
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.ai.enable) {
    environment = {
      systemPackages = with pkgs; [
        lmstudio
        claude-code
      ];
      persistence = {
        "${persistPath}" = {
          directories = [config.services.ollama.home];
        };
      };
    };
    services.ollama = {
      enable = true;
      openFirewall = true;
      syncModels = true;
      package = pkgs.ollama-cuda;
      loadModels = [
        "qwen3-coder-next:q4_K_M"
      ];
    };
  };
}
