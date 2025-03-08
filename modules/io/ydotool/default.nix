{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.io;
in {
  options = {
    modules = {
      io = {
        ydotool = {
          enable = lib.mkEnableOption "Enable ydotool service" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.ydotool.enable) {
    programs = {
      ydotool = {
        inherit (cfg.ydotool) enable;
      };
    };
    users = {
      users = {
        "${config.modules.users.name}" = {
          extraGroups = [config.programs.ydotool.group];
        };
      };
    };
  };
}
