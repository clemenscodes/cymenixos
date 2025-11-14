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
        proto = {
          enable = lib.mkEnableOption "Enable proto caching" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.proto.enable) {
    home = {
      persistence = lib.mkIf osConfig.modules.boot.enable {
        "${osConfig.modules.boot.impermanence.persistPath}${config.home.homeDirectory}" = {
          directories = [
            ".local/share/proto"
          ];
        };
      };
    };
  };
}
