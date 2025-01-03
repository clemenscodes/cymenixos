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
        udisks = {
          enable = lib.mkEnableOption "Enable udisks service to automatically mount usb devices" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.udisks.enable) {
    services = {
      udisks2 = {
        inherit (cfg.udisks) enable;
      };
    };
    home-manager = lib.mkIf (config.modules.home-manager.enable) {
      users = {
        ${config.modules.users.user} = {
          home = {
            packages = [pkgs.udiskie];
          };
          services = {
            udiskie = {
              inherit (cfg.udisks) enable;
              tray = "auto";
            };
          };
        };
      };
    };
  };
}
