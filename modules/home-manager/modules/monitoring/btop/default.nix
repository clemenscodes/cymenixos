{lib, ...}: {config, ...}: let
  cfg = config.modules.monitoring;
in {
  options = {
    modules = {
      monitoring = {
        btop = {
          enable = lib.mkEnableOption "Enable btop monitoring" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.btop.enable) {
    programs = {
      btop = {
        inherit (cfg.btop) enable;
        settings = {
          vim_keys = true;
        };
      };
    };
  };
}
