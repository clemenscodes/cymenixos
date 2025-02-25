{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.boot;
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
    # boot = {
    #   lanzaboote = {
    #     inherit (cfg.secureboot) enable;
    #     pkiBundle = "/etc/secureboot";
    #   };
    # };
  };
}
