{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.monitoring;
in {
  options = {
    modules = {
      monitoring = {
        ncdu = {
          enable = lib.mkEnableOption "Enable ncdu disk usage monitoring" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.ncdu.enable) {
    home = {
      packages = [pkgs.ncdu];
    };
  };
}
