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
        unzip = {
          enable = lib.mkEnableOption "Enable unzip" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.unzip.enable) {
    home = {
      packages = [pkgs.unzip];
    };
  };
}
