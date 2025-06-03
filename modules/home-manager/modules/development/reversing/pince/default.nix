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
    home = {
      packages = [
        pkgs.pince
      ];
    };
  };
}
