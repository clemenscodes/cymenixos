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
          inkscape = {
            enable = lib.mkEnableOption "Enable inkscape" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.inkscape.enable) {
    home = {
      packages = [pkgs.inkscape-with-extensions];
    };
  };
}
