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
        wireshark = {
          enable = lib.mkEnableOption "Enable wireshark" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.wireshark.enable) {
    home = {
      packages = [pkgs.wireshark];
    };
  };
}
