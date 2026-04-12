{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
in {
  options = {
    modules = {
      xdg = {
        enable =
          lib.mkEnableOption "Enable XDG"
          // {
            default = false;
          };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.xdg.enable) {
    xdg = {
      autostart = {
        inherit (cfg.xdg) enable;
      };
      terminal-exec = {
        inherit (cfg.xdg) enable;
      };
      sounds = {
        inherit (cfg.xdg) enable;
      };
      menus = {
        inherit (cfg.xdg) enable;
      };
      icons = {
        inherit (cfg.xdg) enable;
      };
      mime = {
        inherit (cfg.xdg) enable;
      };
      portal = lib.mkIf (cfg.display.gui != "headless") {
        enable = true;
        xdgOpenUsePortal = true;
        extraPortals =
          [
            pkgs.xdg-desktop-portal
            pkgs.xdg-desktop-portal-gtk
          ]
          ++ lib.optionals cfg.display.hyprland.enable [
            pkgs.xdg-desktop-portal-hyprland
          ];
        # Explicit routing is required when multiple portal backends are installed.
        # Without this, xdg-desktop-portal picks backends alphabetically and may
        # choose gtk over hyprland, breaking screen capture in OBS and other apps.
        # Hyprland sets XDG_CURRENT_DESKTOP=Hyprland, so the "Hyprland" block wins.
        config =
          if cfg.display.hyprland.enable
          then {
            common = {
              default = ["gtk"];
            };
            hyprland = {
              default = ["hyprland" "gtk"];
              "org.freedesktop.portal.FileChooser" = ["gtk"];
              "org.freedesktop.portal.OpenURI" = ["gtk"];
            };
          }
          else {
            common = {
              default = ["gtk"];
            };
          };
      };
    };
  };
}
