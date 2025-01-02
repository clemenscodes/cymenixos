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
        nix-prefetch-git = {
          enable = lib.mkEnableOption "Enable nix-prefetch-git" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.nix-prefetch-git.enable) {
    home = {
      packages = [pkgs.nix-prefetch-git];
    };
  };
}
