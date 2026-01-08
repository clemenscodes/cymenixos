{
  pkgs,
  lib,
  ...
}: {
  config,
  osConfig,
  ...
}: let
  cfg = config.modules.security;
  bitwardenPackage =
    if osConfig.modules.display.gui == "headless"
    then pkgs.bitwarden-cli
    else pkgs.bitwarden-desktop;
in {
  options = {
    modules = {
      security = {
        bitwarden = {
          enable = lib.mkEnableOption "Enable bitwarden" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.bitwarden.enable) {
    home = {
      persistence = lib.mkIf (osConfig.modules.boot.enable) {
        "${osConfig.modules.boot.impermanence.persistPath}" = {
          directories = [".config/Bitwarden"];
        };
      };
      packages = [bitwardenPackage];
    };
  };
}
