{
  inputs,
  pkgs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.gaming;
  inherit (config.modules.boot.impermanence) persistPath;
  inherit (config.modules.users) name;
in {
  options = {
    modules = {
      gaming = {
        heroic = {
          enable = lib.mkEnableOption "Enable heroic" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.heroic.enable) {
    environment = {
      systemPackages = [
        pkgs.heroic
        pkgs.gogdl
      ];
      persistence = lib.mkIf (config.modules.boot.enable) {
        ${persistPath} = {
          users = {
            ${name} = {
              directories = [
              ];
            };
          };
        };
      };
    };
  };
}
