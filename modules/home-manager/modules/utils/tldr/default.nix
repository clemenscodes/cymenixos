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
        tldr = {
          enable = lib.mkEnableOption "Enable tldr" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.tldr.enable) {
    home = {
      packages = [pkgs.tldr];
    };
  };
}
