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
            hyprpicker = {
              enable = lib.mkEnableOption "Enable hyprpicker" // {default = false;};
            };
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.hyprpicker.enable) {
    home = {
      packages = [pkgs.hyprpicker];
    };
  };
}
