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
        screenshots = {
          enable = lib.mkEnableOption "Enable screenshots" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.screenshots.enable) {
    home = {
      packages = [
        pkgs.grim
        pkgs.slurp
        pkgs.wl-clipboard
        (import ./screenshot {inherit pkgs;})
        (import ./fullscreenshot {inherit pkgs;})
      ];
    };
  };
}
