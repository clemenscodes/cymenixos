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
        sddm = {
          enable = lib.mkEnableOption "Enable a swag sddm login manager" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.hyprland.enable && cfg.sddm.enable) {
    environment = {
      systemPackages = [
        pkgs.libsForQt5.qt5.qtquickcontrols2
        pkgs.libsForQt5.qt5.qtsvg
        pkgs.libsForQt5.qt5.qtgraphicaleffects
        pkgs.catppuccin-cursors.macchiatoBlue
      ];
    };
    services = {
      displayManager = {
        sddm = {
          inherit (cfg.sddm) enable;
          package = pkgs.kdePackages.sddm;
          enableHidpi = true;
          wayland = {
            enable = cfg.gui == "wayland";
          };
          theme = "catppuccin-macchiato";
          extraPackages = [
            pkgs.kdePackages.breeze-icons
            pkgs.kdePackages.kirigami
            pkgs.kdePackages.plasma5support
            pkgs.kdePackages.qtsvg
            pkgs.kdePackages.qtvirtualkeyboard
          ];
          settings = {
            Theme = lib.mkForce {
              CursorTheme = "catppuccin-macchiato-blue-cursors";
            };
          };
        };
      };
    };
    security = {
      pam = {
        services = {
          sddm = {
            enableGnomeKeyring = config.modules.security.gnome-keyring.enable;
          };
        };
      };
    };
  };
}
