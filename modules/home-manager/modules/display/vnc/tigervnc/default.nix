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
          tigervnc = {
            enable = lib.mkEnableOption "Enable tigervnc" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.tigervnc.enable) {
    home = {
      packages = [pkgs.tigervnc];
    };
  };
}
