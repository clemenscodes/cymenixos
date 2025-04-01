{lib, ...}: {config, ...}: let
  cfg = config.modules.databases;
in {
  options = {
    modules = {
      databases = {
        mongodb = {
          enable = lib.mkEnableOption "Enable mongodb" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.mongodb.enable) {
    services = {
      mongodb = {
        enable = true;
      };
    };
  };
}
