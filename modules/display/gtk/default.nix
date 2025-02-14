{lib, ...}: {config, ...}: let
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
  config = lib.mkIf (cfg.enable && cfg.gtk.enable) {
    programs = {
      dconf = {
        enable = true;
        profiles = {
          user = {
            databases = [
              {
                settings = {
                  "org/gnome/desktop/interface" = {
                    color-scheme = "prefer-dark";
                  };
                };
              }
            ];
          };
        };
      };
    };
    gtk = {
      iconCache = {
        enable = cfg.gtk.enable;
      };
    };
  };
}
