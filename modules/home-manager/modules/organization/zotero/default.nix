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
      persistence = lib.mkIf (osConfig.modules.boot.enable) {
       "${osConfig.modules.boot.impermanence.persistPath}" = {
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
