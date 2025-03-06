{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.gaming;
  inherit (config.modules.boot.impermanence) persistPath;
  inherit (config.modules.users) user;
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
  config = lib.mkIf (cfg.enable && cfg.steam.enable) {
    environment = {
      systemPackages = [
        (pkgs.lutris.override {
          extraPkgs = pkgs: [
            wine
            pkgs.winetricks
          ];
        })
      ];
      persistence = {
        ${persistPath} = {
          users = {
            ${user} = {
              directories = [".cache/lutris"];
            };
          };
        };
      };
    };
  };
}
