{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.display;
in {
  options = {
    modules = {
      display = {
        cursor = {
          enable = lib.mkEnableOption "Enable a cool cursor" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.cursor.enable) {
    home = {
      pointerCursor = {
        name = "catppuccin-macchiato-blue-cursors";
        package = pkgs.catppuccin-cursors.macchiatoBlue;
        size = 16;
      };
    };
  };
}
