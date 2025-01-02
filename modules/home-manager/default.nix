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
  config = {
    system = {
      stateVersion = lib.mkDefault lib.versions.majorMinor lib.version;
    };
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = {inherit inputs pkgs lib system;};
      backupFileExtension = "home-manager-backup";
      users = {
        ${cfg.users.user} = {
          stateVersion = lib.mkDefault lib.versions.majorMinor lib.version;
          imports = [(import ./modules {inherit inputs pkgs lib;})];
        };
      };
    };
  };
}
