{
  pkgs,
  lib,
  ...
}: {
  config,
  osConfig,
  ...
}: let
  cfg = config.modules.organization;
  isDesktop = osConfig.modules.display.gui != "headless";
in {
  options = {
    modules = {
      organization = {
        libreoffice = {
          enable = lib.mkEnableOption "Enable libreoffice" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.libreoffice.enable && isDesktop) {
    home = {
      packages = [pkgs.libreoffice];
    };
  };
}
