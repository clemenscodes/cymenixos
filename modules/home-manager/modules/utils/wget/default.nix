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
        wget = {
          enable = lib.mkEnableOption "Enable wget" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.wget.enable) {
    home = {
      packages = [pkgs.wget];
    };
  };
}
