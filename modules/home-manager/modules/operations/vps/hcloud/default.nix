{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.operations.vps;
in {
  options = {
    modules = {
      operations = {
        vps = {
          hcloud = {
            enable = lib.mkEnableOption "Enable hcloud" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.hcloud.enable) {
    home = {
      packages = [pkgs.hcloud];
    };
  };
}
