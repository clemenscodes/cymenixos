{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.gaming;
in {
  options = {
    modules = {
      gaming = {
        gamemode = {
          enable = lib.mkEnableOption "Enable gamemode" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.gamemode.enable) {
    programs = {
      gamemode = {
        inherit (cfg.gamemode) enable;
        settings = {
          general = {
            renice = 10;
            inhibit_screensaver = 0;
          };
          gpu = {
            gpu_device = 1;
            apply_gpu_optimisations = "accept-responsibility";
            amd_performance_level = "auto";
          };
          custom = {
            start = "${pkgs.libnotify}/bin/notify-send 'Gamemode started'";
            end = "${pkgs.libnotify}/bin/notify-send 'Gamemode ended'";
          };
        };
      };
    };
    users = {
      users = {
        ${config.modules.users.name} = {
          extraGroups = ["gamemode"];
        };
      };
    };
  };
}
