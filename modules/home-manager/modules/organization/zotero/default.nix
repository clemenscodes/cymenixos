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
        zotero = {
          enable = lib.mkEnableOption "Enable zotero" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.zotero.enable && isDesktop) {
    home = {
      packages = [pkgs.zotero];
      persistence = {
        "${osConfig.modules.boot.impermanence.persistPath}${config.home.homeDirectory}" = {
          directories = [
            ".cache/zotero"
            ".zotero"
            "Zotero"
          ];
        };
      };
    };
  };
}
