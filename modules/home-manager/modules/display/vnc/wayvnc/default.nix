{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.display.vnc;
in {
  options = {
    modules = {
      display = {
        vnc = {
          wayvnc = {
            enable = lib.mkEnableOption "Enable wayvnc" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.wayvnc.enable) {
    home = {
      packages = [pkgs.wayvnc];
    };
  };
}
