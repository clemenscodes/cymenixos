{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.display;
  kvantum = pkgs.catppuccin-kvantum.override {
    accent = "blue";
    variant = "macchiato";
  };
in {
  options = {
    modules = {
      display = {
        qt = {
          enable = lib.mkEnableOption "Enable Qt" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.qt.enable) {
    home = {
      packages = [
        pkgs.libsForQt5.qtstyleplugin-kvantum
        pkgs.libsForQt5.qt5ct
        pkgs.libsForQt5.qt5.qtwayland
        pkgs.catppuccin-qt5ct
        pkgs.qt6.qtwayland
        kvantum
      ];
      sessionVariables = {
        QT_QPA_PLATFORM = "wayland;xcb";
        QT_QPA_PLATFORMTHEME = "kvantum";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        QT_AUTO_SCREEN_SCALE_FACTOR = "1";
        SDL_VIDEODRIVER = "wayland";
        GDK_BACKEND = "wayland,x11,*";
      };
    };
    qt = {
      enable = cfg.qt.enable;
      platformTheme = {
        name = "kvantum";
      };
      style = {
        name = "kvantum";
        package = kvantum;
      };
    };
  };
}
