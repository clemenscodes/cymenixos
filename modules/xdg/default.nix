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
        enable = lib.mkEnableOption "Enable XDG" // {default = false;};
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
      portal = {
        extraPortals = lib.mkForce [
          pkgs.xdg-desktop-portal
          pkgs.xdg-desktop-portal-wlr
          pkgs.xdg-desktop-portal-hyprland
        ];
      };
    };
  };
}
