{lib, ...}: {config, ...}: let
  cfg = config.modules;
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
