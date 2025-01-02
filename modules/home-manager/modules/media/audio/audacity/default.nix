{
  pkgs,
  lib,
  ...
}: {
  config,
  osConfig,
  ...
}: let
  cfg = config.modules.media.audio;
  isDesktop = osConfig.modules.display.gui != "headless";
in {
  options = {
    modules = {
      media = {
        audio = {
          audacity = {
            enable = lib.mkEnableOption "Enable audacity" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.audacity.enable && isDesktop) {
    home = {
      packages = [pkgs.audacity];
    };
  };
}
