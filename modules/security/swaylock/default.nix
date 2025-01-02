{lib, ...}: {config, ...}: let
  cfg = config.modules;
  inherit (cfg.users) user;
  useSwaylock = config.home-manager.users.${user}.modules.display.lockscreen.swaylock.enable;
in {
  options = {
    modules = {
      security = {
        swaylock = {
          enable = lib.mkEnableOption "Enable swaylock PAM" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf cfg.security.swaylock.enable {
    security = {
      pam = {
        services = {
          swaylock = {};
        };
      };
    };
  };
}
