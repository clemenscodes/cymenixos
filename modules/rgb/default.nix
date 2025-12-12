{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
  inherit (cfg.rgb) enable;
in {
  options = {
    modules = {
      rgb = {
        enable = lib.mkEnableOption "Enable RGB" // {default = false;};
      };
    };
  };
  config = lib.mkIf (cfg.enable && enable) {
    services = {
      hardware = {
        openrgb = {
          inherit enable;
        };
      };
    };
    environment = {
      systemPackages = with pkgs; [openrgb-with-all-plugins];
    };
  };
}
