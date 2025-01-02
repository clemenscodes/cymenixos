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
  config = lib.mkIf (cfg.enable && cfg.home-manager.enable) {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = {inherit inputs pkgs lib system;};
      backupFileExtension = "home-manager-backup";
      users = {
        ${cfg.users.user} = {
          imports = [(import ./modules {inherit inputs pkgs lib;})];
        };
      };
    };
  };
}
