{lib, ...}: {
  config,
  osConfig,
  ...
}: let
  cfg = config.modules;
  osCfg = osConfig.modules;
in {
  options = {
    modules = {
      fonts = {
        enable = lib.mkEnableOption "Enable fonts" // {default = false;};
      };
    };
  };
  config = lib.mkIf (osCfg.fonts.enable && cfg.enable && cfg.fonts.enable) {
    fonts = {
      fontconfig = {
        inherit (cfg.fonts) enable;
      };
    };
  };
}
