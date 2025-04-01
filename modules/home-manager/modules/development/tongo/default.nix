{
  inputs,
  pkgs,
  lib,
  ...
}: {
  system,
  config,
  ...
}: let
  cfg = config.modules.development;
in {
  options = {
    modules = {
      development = {
        tongo = {
          enable = lib.mkEnableOption "Enable tongo support" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.tongo.enable) {
    home = {
      packages = [pkgs.tongo];
    };
  };
}
