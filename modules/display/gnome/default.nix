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
        gnome = {
          enable = lib.mkEnableOption "Enable GNOME" // {default = false;};
        };
      };
    };
  };

  config = lib.mkIf (cfg.enable && cfg.gnome.enable) {
    services = {
      xserver = {
        inherit (cfg.gnome) enable;
        desktopManager = {
          gnome = {
            inherit (cfg.gnome) enable;
          };
        };
        displayManager = {
          gdm = {
            inherit (cfg.gnome) enable;
          };
        };
      };

      udev = {
        packages = [pkgs.gnome-settings-daemon];
      };
    };

    programs = {
      dconf = {
        inherit (cfg.gnome) enable;
      };
    };

    environment = {
      systemPackages = [
        pkgs.adwaita-icon-theme
        pkgs.gnomeExtensions.appindicator
      ];
      gnome = {
        excludePackages = with pkgs; [
          orca
          evince
          geary
          gnome-bluetooth
          gnome-software
          yelp
          totem
          snapshot
          simple-scan
          gnome-connections
          gnome-weather
          gnome-music
          gnome-photos
          gnome-maps
          gnome-logs
          gnome-font-viewer
          gnome-contacts
          gnome-console
          gnome-calendar
          gnome-calculator
          gnome-text-editor
          epiphany
          baobab
          gnome-user-docs
          gnome-tour
          tali
          atomix
          cheese
          iagno
          gnome-characters
        ];
      };
    };

    home-manager = lib.mkIf cfg.gnome.enable {
      users = {
        ${config.modules.users.name} = {
          dconf = {
            settings = {
              "org/gnome/shell" = {
                favorite-apps = [
                  "yazi.desktop"
                  "kitty.desktop"
                ];
              };
              "org/gnome/desktop/interface" = {
                color-scheme = "prefer-dark";
              };
              "org/gnome/desktop/applications/terminal" = {
                exec = "kitty";
              };
            };
          };
        };
      };
    };
  };
}
