{
  inputs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.networking.proxy;
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["charles"];
    };
  };
in {
  options = {
    modules = {
      networking = {
        proxy = {
          charles = {
            enable = lib.mkEnableOption "Enable charles web debugging proxy" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.charles.enable) {
    home = {
      packages = [pkgs.charles];
    };
  };
}
