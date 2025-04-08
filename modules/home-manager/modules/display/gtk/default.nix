{
  pkgs,
  lib,
  ...
}: {
  config,
  osConfig,
  ...
}: let
  iconTheme = pkgs.catppuccin-papirus-folders.override {
    flavor = "macchiato";
    accent = "blue";
  };
  theme = {
    name = "Colloid-Dark-Catppuccin";
    package = pkgs.colloid-gtk-theme.override {tweaks = ["catppuccin"];};
  };
  themePath = "${theme.package}/share/themes/${theme.name}";
  cfg = config.modules.display;
in {
  options = {
    modules = {
      display = {
        gtk = {
          enable = lib.mkEnableOption "Enable GTK" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.gtk.enable && osConfig.modules.display.gtk.enable) {
    home = {
      sessionVariables = {
        GTK_THEME = theme.name;
      };
      packages = [
        pkgs.libsForQt5.breeze-icons
        pkgs.hicolor-icon-theme
        pkgs.zenity
      ];
      file = {
        ".icons/Papirus-Dark" = {
          source = "${iconTheme}/share/icons/Papirus-Dark";
        };
        ".local/share/.icons/Papirus-Dark" = {
          source = "${iconTheme}/share/icons/Papirus-Dark";
        };
      };
    };
    xdg = {
      desktopEntries = {
        zenity = {
          name = "Zenity";
          type = "Application";
          genericName = "Dialog window";
          icon = "zenity";
          exec = "${lib.getExe pkgs.zenity}";
          terminal = false;
        };
      };
    };
    gtk = {
      inherit (cfg.gtk) enable;
      inherit theme;
      cursorTheme = lib.mkForce {
        package = pkgs.catppuccin-cursors.macchiatoBlue;
        name = "catppuccin-macchiato-blue-cursors";
      };
      iconTheme = {
        package = iconTheme;
        name = "Papirus-Dark";
      };
      font = {
        package = pkgs.nerd-fonts.iosevka;
        name = "${osConfig.modules.fonts.defaultFont}";
        inherit (osConfig.modules.fonts) size;
      };
      gtk2 = {
        configLocation = "${config.xdg.configHome}/gtk-2.0/settings.ini";
        extraConfig = ''
          gtk-application-prefer-dark-theme=1
        '';
      };
      gtk3 = {
        extraConfig = {
          gtk-application-prefer-dark-theme = 1;
        };
      };
      gtk4 = {
        extraConfig = {
          gtk-application-prefer-dark-theme = 1;
        };
      };
    };
    xdg = {
      configFile = {
        "gtk-2.0/assets".source = "${themePath}/gtk-2.0/assets";
        "gtk-2.0/apps.rc".source = "${themePath}/gtk-2.0/apps.rc";
        "gtk-2.0/gtkrc".source = "${themePath}/gtk-2.0/gtkrc";
        "gtk-2.0/hacks.rc".source = "${themePath}/gtk-2.0/hacks.rc";
        "gtk-2.0/main.rc".source = "${themePath}/gtk-2.0/main.rc";
        "gtk-3.0/assets".source = "${themePath}/gtk-3.0/assets";
        "gtk-3.0/gtk.css".source = "${themePath}/gtk-3.0/gtk.css";
        "gtk-3.0/gtk-dark.css".source = "${themePath}/gtk-3.0/gtk-dark.css";
        "gtk-4.0/assets".source = "${themePath}/gtk-4.0/assets";
        "gtk-4.0/gtk.css".source = "${themePath}/gtk-4.0/gtk.css";
        "gtk-4.0/gtk-dark.css".source = "${themePath}/gtk-4.0/gtk-dark.css";
      };
    };
  };
}
