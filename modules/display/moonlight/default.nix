{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.display;
in {
  options = {
    modules = {
      display = {
        moonlight = {
          enable = lib.mkEnableOption "Enable the Moonlight desktop/game streaming client (pairs with a Sunshine host)" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.moonlight.enable) {
    environment = {
      systemPackages = [pkgs.moonlight-qt];
    };
  };
}
