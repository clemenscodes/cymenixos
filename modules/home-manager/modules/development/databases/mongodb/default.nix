{
  inputs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.development;
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["mongodb-compass"];
    };
  };
in {
  options = {
    modules = {
      development = {
        mongodb = {
          enable = lib.mkEnableOption "Enable mongodb" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.mongodb.enable) {
    home = {
      packages = [pkgs.mongodb-compass];
    };
  };
}
