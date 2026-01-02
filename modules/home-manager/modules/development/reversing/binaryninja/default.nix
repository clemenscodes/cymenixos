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
    config = {
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["binaryninja-free"];
    };
  };
in {
  options = {
    modules = {
      development = {
        reversing = {
          binaryninja = {
            enable = lib.mkEnableOption "Enable binary ninja" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.binaryninja.enable) {
    home = {
      packages = [
        pkgs.binaryninja-free
      ];
    };
  };
}
