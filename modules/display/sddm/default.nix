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
  config = lib.mkIf (cfg.enable && cfg.sddm.enable) {
    environment = {
      systemPackages = [
        pkgs.qt5.qtquickcontrols2
        pkgs.qt5.qtsvg
        pkgs.qt5.qtgraphicaleffects
        pkgs.catppuccin-cursors.macchiatoBlue
      ];
    };
    services = {
      displayManager = {
        autoLogin = {
          inherit (config.modules.users) user;
        };
        sddm = {
          inherit (cfg.sddm) enable;
          autoLogin = {
            relogin = true;
          };
          enableHidpi = true;
          wayland = {
            enable = cfg.gui == "wayland";
          };
          extraPackages = [
            pkgs.kdePackages.kirigami
            pkgs.kdePackages.plasma5support
            pkgs.kdePackages.qtsvg
            pkgs.kdePackages.qtvirtualkeyboard
          ];
          settings = {
            General = {
              DisplayServer = "wayland";
            };
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
