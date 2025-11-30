{
  pkgs,
  lib,
  ...
}: {
  config,
  osConfig,
  ...
}: let
  cfg = config.modules.media.communication;
  isDesktop = osConfig.modules.display.gui != "headless";
in {
  options = {
    modules = {
      media = {
        communication = {
          fractal = {
            enable = lib.mkEnableOption "Enable fractal" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.fractal.enable && isDesktop) {
    home = {
      packages = [pkgs.fractal];
      persistence = lib.mkIf (osConfig.modules.boot.enable) {
        "${osConfig.modules.boot.impermanence.persistPath}${config.home.homeDirectory}" = {
          directories = [];
        };
      };
    };
  };
}
