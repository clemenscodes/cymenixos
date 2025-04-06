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
        w3champions = {
          enable = lib.mkEnableOption "Enable W3Champions" // {default = false;};
          prefix = lib.mkOption {
            type = lib.types.str;
            default = "Games/W3Champions";
            example = ".local/share/games/W3Champions";
            description = "Where the wineprefix will be for W3Champions, relative to $HOME";
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.w3champions.enable) {
    environment = {
      persistence = {
        ${config.modules.boot.impermanence.persistPath} = {
          users = {
            ${config.modules.users.name} = {
              directories = ["Games"];
            };
          };
        };
      };
    };
  };
}
