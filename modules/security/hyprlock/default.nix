{lib, ...}: {config, ...}: let
  cfg = config.modules;
in {
  options = {
    modules = {
      security = {
        hyprlock = {
          enable = lib.mkEnableOption "Enable hyprlock PAM" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf cfg.security.hyprlock.enable {
    security = {
      pam = {
        services = {
          hyprlock = {};
        };
      };
    };
  };
}
