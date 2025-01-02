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
        zip = {
          enable = lib.mkEnableOption "Enable zip" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.zip.enable) {
    home = {
      packages = [pkgs.zip];
    };
  };
}
