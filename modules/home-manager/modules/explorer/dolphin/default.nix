{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.explorer;
in {
  options = {
    modules = {
      explorer = {
        dolphin = {
          enable = lib.mkEnableOption "Enable dolphin file browser" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.dolphin.enable) {
    home = {
      packages = [pkgs.dolphin];
    };
  };
}
