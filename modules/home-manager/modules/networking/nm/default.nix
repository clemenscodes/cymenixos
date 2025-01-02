{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.networking;
in {
  options = {
    modules = {
      networking = {
        nm = {
          enable = lib.mkEnableOption "Enable network-manager applet" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.nm.enable) {
    home = {
      packages = [pkgs.networkmanagerapplet];
    };
    services = {
      network-manager-applet = {
        inherit (cfg.nm) enable;
      };
    };
  };
}
