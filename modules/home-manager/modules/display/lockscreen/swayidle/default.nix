{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.display.lockscreen;
in {
  options = {
    modules = {
      display = {
        lockscreen = {
          swayidle = {
            enable = lib.mkEnableOption "Enable swayidle" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.swayidle.enable) {
    home = {
      packages = [
        pkgs.swayidle
        (import ./detectidle {inherit pkgs;})
      ];
    };
  };
}
