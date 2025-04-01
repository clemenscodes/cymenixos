{
  inputs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.databases;
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["mongodb"];
    };
  };
in {
  options = {
    modules = {
      databases = {
        mongodb = {
          enable = lib.mkEnableOption "Enable mongodb" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.mongodb.enable) {
    services = {
      mongodb = {
        enable = true;
        package = pkgs.mongodb;
      };
    };
  };
}
