{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.media.video;
in {
  options = {
    modules = {
      media = {
        video = {
          vhs = {
            enable = lib.mkEnableOption "Enable vhs to record terminal outputs" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.vhs.enable) {
    home = {
      packages = [pkgs.vhs];
    };
  };
}
