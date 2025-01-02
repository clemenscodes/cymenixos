{lib, ...}: {config, ...}: let
  cfg = config.modules.utils;
in {
  options = {
    modules = {
      utils = {
        bat = {
          enable = lib.mkEnableOption "Enable bat" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.bat.enable) {
    programs = {
      bat = {
        inherit (cfg.bat) enable;
      };
    };
  };
}
