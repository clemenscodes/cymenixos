{
  inputs,
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
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["7zz"];
    };
  };
in {
  options = {
    modules = {
      gaming = {
        nexusmods = {
          enable = lib.mkEnableOption "Enable nexusmods" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.nexusmods.enable) {
    environment = {
      systemPackages = [pkgs.nexusmods-app-unfree];
      persistence = {
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
