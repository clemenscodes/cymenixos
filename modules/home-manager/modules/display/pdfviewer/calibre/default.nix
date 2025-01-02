{
  inputs,
  lib,
  ...
}: {
  system,
  config,
  ...
}: let
  cfg = config.modules.display.pdfviewer;
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["calibre" "unrar"];
    };
    overlays = [
      (self: super: {
        calibre = super.calibre.override {
          unrarSupport = true;
        };
      })
    ];
  };
in {
  options = {
    modules = {
      display = {
        pdfviewer = {
          calibre = {
            enable = lib.mkEnableOption "Enable calibre" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.calibre.enable) {
    home = {
      packages = [pkgs.calibre];
    };
  };
}
