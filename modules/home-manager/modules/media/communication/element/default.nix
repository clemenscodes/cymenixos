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
          element = {
            enable = lib.mkEnableOption "Enable element" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.element.enable && isDesktop) {
    home = {
      packages = [pkgs.element-desktop];
      persistence = lib.mkIf (osConfig.modules.boot.enable) {
       "${osConfig.modules.boot.impermanence.persistPath}" = {
          directories = [".config/Element"];
        };
      };
    };
  };
}
