{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.media.editing;
in {
  options = {
    modules = {
      media = {
        editing = {
          gimp = {
            enable = lib.mkEnableOption "Enable GIMP" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.gimp.enable) {
    home = {
      packages = [pkgs.gimp];
    };
  };
}
