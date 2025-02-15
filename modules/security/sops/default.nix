{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.security;
  inherit (config.modules.users) user;
  inherit (config.modules.boot.impermanence) persistPath;
in {
  imports = [inputs.sops-nix.nixosModules.sops];
  options = {
    modules = {
      security = {
        sops = {
          enable = lib.mkEnableOption "Enable secrets using SOPS" // {default = false;};
        };
      };
    };
  };
  config = {
    environment = {
      systemPackages = [
        (import ./setupsops.nix {inherit inputs pkgs lib;})
        pkgs.sops
        pkgs.age
        pkgs.ssh-to-age
      ];
      persistence = lib.mkIf (cfg.enable && cfg.sops.enable) {
        ${persistPath} = {
          users = {
            ${user} = {
              directories = [
                ".config/sops"
                ".config/sops-nix"
              ];
            };
          };
        };
      };
    };
    sops = lib.mkIf (cfg.enable && cfg.sops.enable) {
      gnupg = {
        home = "${persistPath}/home/${user}/.config/gnupg";
        sshKeyPaths = [];
      };
      age = {
        sshKeyPaths = [];
      };
    };
  };
}
