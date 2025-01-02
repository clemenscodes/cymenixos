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
          backgroundremover = {
            enable = lib.mkEnableOption "Enable backgroundremover" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.backgroundremover.enable) {
    home = {
      packages = [pkgs.backgroundremover];
    };
  };
}
