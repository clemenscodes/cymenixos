{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.utils;
in {
  options = {
    modules = {
      utils = {
        lsusb = {
          enable = lib.mkEnableOption "Enable lsusb" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.lsusb.enable) {
    home = {
      packages = [pkgs.usbutils];
    };
  };
}
