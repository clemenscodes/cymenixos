{
  inputs,
  pkgs,
  lib,
  ...
}: {
  config,
  osConfig,
  ...
}: let
  cfg = config.modules.display.bar;
in {
  options = {
    modules = {
      display = {
        bar = {
          quickshell = {
            enable = lib.mkEnableOption "Enable Quickshell" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.quickshell.enable) {
    programs = {
      quickshell = {
        enable = true;
        package = pkgs.quickshell;
        configs = {
          amaru = ./qml;
        };
        activeConfig = "amaru";
        systemd = {
          enable = true;
          target = "hyprland-session.target";
        };
      };
    };
  };
}
