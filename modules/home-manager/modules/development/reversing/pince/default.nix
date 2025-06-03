{
  inputs,
  lib,
  ...
}: {
  osConfig,
  config,
  system,
  ...
}: let
  cfg = config.modules.development.reversing;
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [
      (final: prev: {
        pince = prev.callPackage ./package.nix {};
      })
    ];
  };
in {
  options = {
    modules = {
      development = {
        reversing = {
          pince = {
            enable = lib.mkEnableOption "Enable PINCE" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.pince.enable) {
    home = {
      packages = [pkgs.pince];
      persistence = {
        "${osConfig.modules.boot.impermanence.persistPath}${config.home.homeDirectory}" = {
          directories = [".config/PINCE"];
        };
      };
    };
    xdg = {
      desktopEntries = {
        pince = {
          name = "PINCE";
          genericName = "PINCE is not Cheat Engine";
          comment = "Reverse engineering tool for linux games";
          type = "Application";
          exec = "sudo -E ${pkgs.pince}/bin/PINCE %f";
          terminal = false;
          icon = "${pkgs.pince}/share/pince/media/logo/ozgurozbek/pince_big_red.png";
          categories = ["GTK" "System"];
          startupNotify = true;
        };
      };
    };
  };
}
