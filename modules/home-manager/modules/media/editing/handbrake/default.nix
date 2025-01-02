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
          handbrake = {
            enable = lib.mkEnableOption "Enable handbrake" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.handbrake.enable) {
    home = {
      packages = [pkgs.handbrake];
    };
  };
}
