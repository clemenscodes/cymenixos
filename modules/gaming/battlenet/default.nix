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
in {
  imports = [
    (import ./warcraft {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      gaming = {
        battlenet = {
          enable = lib.mkEnableOption "Enable battlenet" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.battlenet.enable) {
    environment = {
      systemPackages = [inputs.battlenet.packages.${system}.battlenet];
      persistence = {
        ${config.modules.boot.impermanence.persistPath} = {
          users = {
            ${config.modules.users.name} = {
              directories = [
                ".local/share/wineprefixes/bnet"
              ];
            };
          };
        };
      };
    };
  };
}
