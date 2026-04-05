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
        razer = {
          enable = lib.mkEnableOption "Enable Razer peripheral support" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.razer.enable) {
    hardware = {
      openrazer = {
        enable = true;
        users = [config.modules.users.name];
      };
    };
    environment = {
      systemPackages = [
        pkgs.polychromatic
        pkgs.razergenie
      ];
    };
  };
}
