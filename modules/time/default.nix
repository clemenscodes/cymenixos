{lib, ...}: {config, ...}: let
  cfg = config.modules;
in {
  options = {
    modules = {
      time = {
        enable = lib.mkEnableOption "Enable time settings" // {default = false;};
        defaultTimeZone = lib.mkOption {
          type = lib.types.str;
          default = "Europe/Berlin";
        };
        useLocalTime = lib.mkEnableOption "Enable localtimed service" // {default = false;};
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.time.enable) {
    time = {
      timeZone = lib.mkDefault cfg.time.defaultTimeZone;
    };
    services = {
      localtimed = {
        enable = cfg.time.useLocalTime;
      };
    };
  };
}
