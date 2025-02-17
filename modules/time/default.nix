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
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.time.enable) {
    time = {
      timeZone = cfg.time.defaultTimeZone;
    };
    services = {
      localtimed = {
        inherit (cfg.time) enable;
      };
    };
  };
}
