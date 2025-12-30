{
  inputs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.utils;
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          "unrar"
        ];
    };
  };
in {
  options = {
    modules = {
      utils = {
        unrar = {
          enable = lib.mkEnableOption "Enable unrar" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.unrar.enable) {
    home = {
      packages = [pkgs.unrar];
    };
  };
}
