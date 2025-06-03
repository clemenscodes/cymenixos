{
  inputs,
  lib,
  ...
}: {
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
    xdg = {
      desktopEntries = {
        gparted = {
          name = "PINCE";
          genericName = "PINCE is not Cheat Engine";
          comment = "Reverse engineering tool for linux games";
          type = "Application";
          exec = "sudo -E ${pkgs.pince}/bin/pince %f";
          terminal = false;
          icon = "${pkgs.pince}/share/pince/media/logo/ozgurozbek/pince_big_red.png";
          categories = ["GTK" "System"];
          startupNotify = true;
        };
      };
    };
    home = {
      packages = [
        pkgs.pince
      ];
    };
  };
}
