{
  inputs,
  pkgs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules;
in {
  imports = [
    (import ./cachix {inherit inputs pkgs lib;})
    (import ./nix {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      config = {
        enable = lib.mkEnableOption "Enable common configurations" // {default = cfg.enable;};
      };
    };
  };
  config = lib.mkIf cfg.enable {
    nixpkgs = {
      hostPlatform = system;
    };
  };
}
