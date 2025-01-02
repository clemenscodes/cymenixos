{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.display.imageviewer;
in {
  options = {
    modules = {
      display = {
        imageviewer = {
          swayimg = {
            enable = lib.mkEnableOption "Enable swayimg" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.swayimg.enable) {
    home = {
      packages = [pkgs.swayimg];
    };
  };
}
