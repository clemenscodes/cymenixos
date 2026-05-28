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

  # 5-hour block token quotas per Claude Code plan tier.
  planQuotas = {
    pro = 19000;
    max5 = 88000;
    max20 = 220000;
  };
  claudeQuota =
    if cfg.waybar.claudeMonitor.quotaTokens != null
    then cfg.waybar.claudeMonitor.quotaTokens
    else planQuotas.${cfg.waybar.claudeMonitor.plan};
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
    home = {
      packages = [
        pkgs.libappindicator-gtk3
        pkgs.libdbusmenu-gtk3
        (import ./helpers/qs-mail {inherit inputs pkgs lib;})
        (import ./helpers/qs-claude-monitor {
          inherit pkgs;
          quota = claudeQuota;
        })
        (import ./helpers/qs-nvidia {inherit pkgs;})
      ];
    };
    programs = {
      quickshell = {
        enable = true;
        package = pkgs.quickshell;
        configs = {
          cymenix = ./qml;
        };
        activeConfig = "cymenix";
        systemd = {
          enable = true;
          target = "hyprland-session.target";
        };
      };
    };
  };
}
