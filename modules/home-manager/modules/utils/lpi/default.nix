{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.utils;
in {
  options = {
    modules = {
      utils = {
        lpi = {
          enable = lib.mkEnableOption "Enable lpi to load project information" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.lpi.enable) {
    home = {
      packages = [
        pkgs.moon
        inputs.lpi.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
  };
}
