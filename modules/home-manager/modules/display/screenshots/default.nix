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
        pkgs.swappy
        (import ./screenshot {inherit pkgs;})
        (import ./fullscreenshot {inherit pkgs;})
      ];
    };
    xdg = {
      configFile = {
        "swappy/config" = {
          text = ''
            [Default]
            save_dir=${config.xdg.dataHome}/images/screenshots
          '';
        };
      };
    };
  };
}
