{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
in {
  imports = [inputs.home-manager.nixosModules.home-manager];
  options = {
    modules = {
      home-manager = {
        enable = lib.mkEnableOption "Enable home-manager" // {default = false;};
      };
    };
  };
  config = {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = {inherit inputs pkgs lib;};
      backupFileExtension = "home-manager-backup";
      users = {
        ${cfg.users.user} = {
          stateVersion = lib.mkDefault cfg.system.defaultVersion;
          imports = [(import ./modules {inherit inputs pkgs lib;})];
        };
      };
    };
  };
}
