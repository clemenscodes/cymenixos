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
      persistence = {
        "${osConfig.modules.boot.impermanence.persistPath}${config.home.homeDirectory}" = {
          # directories = [".config/teams"];
        };
      };
    };
  };
}
