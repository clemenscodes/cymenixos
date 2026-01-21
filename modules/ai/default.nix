{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
in {
  options = {
    modules = {
      ai = {
        enable = lib.mkEnableOption "Enable AI support" // {default = false;};
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.ai.enable) {
    services.ollama = {
      enable = true;
      loadModels = ["qwen3-coder:30b-a3b-q4_K_M"];
      environmentVariables = {
        OLLAMA_SYSTEM_PROMPT = ''
          You are a senior software engineer.
          Prefer minimal diffs.
          Ask before making assumptions.
        '';
      };
    };
  };
}
