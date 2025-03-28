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
          enable = lib.mkEnableOption "Enable w3champions" // {default = false;};
          prefix = lib.mkOption {
            type = lib.types.str;
            default = "Games/w3champions";
            example = ".local/share/games/w3champions";
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
              directories = [cfg.w3champions.prefix];
            };
          };
        };
      };
    };
    networking = {
      firewall = {
        enable = lib.mkForce false;
        allowedTCPPorts = [
          1337
          3552
        ];
        allowedUDPPorts = [
          1337
          3552
        ];
      };
    };
  };
}
