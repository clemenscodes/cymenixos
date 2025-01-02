{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.utils;
in {
  options = {
    modules = {
      utils = {
        nix-prefetch-github = {
          enable = lib.mkEnableOption "Enable nix-prefetch-github" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.nix-prefetch-github.enable) {
    home = {
      packages = [pkgs.nix-prefetch-github];
    };
  };
}
