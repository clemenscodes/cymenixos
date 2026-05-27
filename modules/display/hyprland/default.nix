{
  inputs,
  lib,
  pkgs,
  ...
}: {config, ...}: let
  cfg = config.modules.display;
in {
  options = {
    modules = {
      display = {
        hyprland = {
          enable = lib.mkEnableOption "Enable anime titties" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.hyprland.enable) {
    programs = {
      hyprland = {
        inherit (cfg.hyprland) enable;
        package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
        portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
        xwayland = {
          inherit (cfg.hyprland) enable;
        };
      };
    };
    xdg.portal.extraPortals = lib.mkForce [
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland
    ];
  };
}
