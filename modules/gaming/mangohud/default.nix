{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.gaming;
in {
  options = {
    modules = {
      gaming = {
        mangohud = {
          enable = lib.mkEnableOption "Enable mangohud" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.mangohud.enable) {
    environment = {
      systemPackages = [
        pkgs.mangohud_git
        pkgs.mangohud32_git
        pkgs.goverlay
      ];
    };
  };
}
