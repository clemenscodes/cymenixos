{
  inputs,
  lib,
  ...
}: {
  system,
  config,
  ...
}: let
  cfg = config.modules.development;
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["postman"];
    };
  };
in {
  options = {
    modules = {
      development = {
        postman = {
          enable = lib.mkEnableOption "Enable postman support" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.postman.enable) {
    home = {
      packages = [pkgs.postman];
    };
  };
}
