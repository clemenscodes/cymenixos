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
          kdenlive = {
            enable = lib.mkEnableOption "Enable kdenlive" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.kdenlive.enable) {
    home = {
      packages = [
        pkgs.glaxnimate
        pkgs.kdenlive
      ];
    };
  };
}
