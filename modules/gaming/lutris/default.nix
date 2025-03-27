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
        lutris = {
          enable = lib.mkEnableOption "Enable lutris" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.lutris.enable) {
    environment = {
      systemPackages = [pkgs.lutris];
      persistence = {
        ${persistPath} = {
          users = {
            ${name} = {
              directories = [
                "Games"
                ".cache/lutris"
                ".local/share/lutris"
              ];
            };
          };
        };
      };
    };
    home-manager = lib.mkIf (config.modules.home-manager.enable) {
      users = {
        ${name} = {
          xdg = {
            dataFile = {
              "lutris/runners/proton/proton-ge" = {
                source = pkgs.proton-ge-bin.steamcompattool;
              };
            };
          };
        };
      };
    };
  };
}
