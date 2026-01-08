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
          teams = {
            enable = lib.mkEnableOption "Enable teams" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.teams.enable && isDesktop) {
    home = {
      packages = [pkgs.teams-for-linux];
      persistence = lib.mkIf (osConfig.modules.boot.enable) {
       "${osConfig.modules.boot.impermanence.persistPath}" = {
          directories = [".config/teams-for-linux"];
        };
      };
    };
  };
}
