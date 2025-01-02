{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.display.compositor.hyprland;
in {
  options = {
    modules = {
      display = {
        compositor = {
          hyprland = {
            hyprsunset = {
              enable = lib.mkEnableOption "Enable hyprsunset" // {default = false;};
            };
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.hyprsunset.enable) {
    home = {
      packages = [pkgs.hyprsunset];
    };
  };
}
