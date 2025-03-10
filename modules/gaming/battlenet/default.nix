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
        ${persistPath} = {
          users = {
            ${name} = {
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
