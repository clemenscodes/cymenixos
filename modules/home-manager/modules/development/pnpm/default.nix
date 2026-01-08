{
  inputs,
  pkgs,
  lib,
  ...
}: {
  system,
  config,
  osConfig,
  ...
}: let
  cfg = config.modules.development;
in {
  options = {
    modules = {
      development = {
        pnpm = {
          enable = lib.mkEnableOption "Enable pnpm dependency caching" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.pnpm.enable) {
    home = {
      persistence = lib.mkIf osConfig.modules.boot.enable {
       "${osConfig.modules.boot.impermanence.persistPath}" = {
          directories = [
            ".local/share/pnpm"
          ];
        };
      };
    };
  };
}
