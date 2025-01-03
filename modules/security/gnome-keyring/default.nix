{lib, ...}: {config, ...}: let
  cfg = config.modules.security;
in {
  options = {
    modules = {
      security = {
        gnome-keyring = {
          enable = lib.mkEnableOption "Enable gnome-keyring" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.gnome-keyring.enable) {
    services = {
      gnome = {
        gnome-keyring = {
          inherit (cfg.gnome-keyring) enable;
        };
      };
    };
  };
}
