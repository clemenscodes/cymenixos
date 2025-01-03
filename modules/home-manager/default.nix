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
  options = {
    modules = {
      home-manager = {
        enable = lib.mkEnableOption "Enable home-manager" // {default = false;};
      };
    };
  };
  config = {
    imports = [inputs.home-manager.nixosModules.home-manager];
    system = {
      stateVersion = lib.mkDefault (lib.versions.majorMinor lib.version);
    };
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = {inherit inputs pkgs system;};
      backupFileExtension = "home-manager-backup";
      users = {
        ${cfg.users.user} = {
          imports = [(import ./modules {inherit inputs pkgs lib;})];
          home = {
            stateVersion = lib.mkDefault (lib.versions.majorMinor lib.version);
          };
        };
      };
    };
  };
}
