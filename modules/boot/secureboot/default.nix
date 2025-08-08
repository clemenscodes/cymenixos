{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.boot;
  inherit (cfg) biosSupport efiSupport device;
in {
  # imports = [inputs.lanzaboote.nixosModules.lanzaboote];
  options = {
    modules = {
      boot = {
        secureboot = {
          enable = lib.mkEnableOption "Enables secureboot" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.secureboot.enable) {
    # environment = {
    #   systemPackages = [pkgs.sbctl];
    #   persistence = {
    #     ${config.modules.boot.impermanence.persistPath} = {
    #       directories = [config.booot.lanzaboote.pkiBundle];
    #     };
    #   };
    # };
    boot = {
      loader = {
        limine = {
          enable = true;
          inherit efiSupport biosSupport;
          biosDevice = device;
          efiInstallAsRemovable = efiSupport;
          panicOnChecksumMismatch = true;
          partitionIndex = 2;
          secureBoot = {
            enable = false;
            sbctl = pkgs.sbctl;
          };
          extraConfig = ''

          '';
        };
      };
      # lanzaboote = {
      #   inherit (cfg.secureboot) enable;
      #   pkiBundle = "/etc/secureboot";
      # };
    };
  };
}
