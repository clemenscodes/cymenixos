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
        p7zip = {
          enable = lib.mkEnableOption "Enable p7zip" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.p7zip.enable) {
    home = {
      packages = [pkgs.p7zip];
    };
  };
}
