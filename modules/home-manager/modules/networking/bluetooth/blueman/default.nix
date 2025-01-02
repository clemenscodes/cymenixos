{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.networking.bluetooth;
in {
  options = {
    modules = {
      networking = {
        bluetooth = {
          blueman = {
            enable = lib.mkEnableOption "Enable blueman" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.blueman.enable) {
    home = {
      packages = [pkgs.blueman];
    };
    services = {
      blueman-applet = {
        inherit (cfg.blueman) enable;
      };
    };
  };
}
