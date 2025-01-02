{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.networking.proxy;
in {
  options = {
    modules = {
      networking = {
        proxy = {
          mitmproxy = {
            enable = lib.mkEnableOption "Enable mitmproxy" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.mitmproxy.enable) {
    home = {
      packages = [pkgs.mitmproxy];
    };
  };
}
