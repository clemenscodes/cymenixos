{
  pkgs,
  lib,
  ...
}: {
  config,
  osConfig,
  ...
}: let
  cfg = config.modules.media.communication;
  isDesktop = osConfig.modules.display.gui != "headless";
  element = pkgs.element-desktop;
  elementIcon = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/element-hq/element-desktop/refs/heads/develop/res/img/element.png";
    sha256 = "sha256-FDq3fPk6imYMWxJJnJPH+gBAwBklv+DjHEc42mqmgoU=";
  };
in {
  options = {
    modules = {
      media = {
        communication = {
          element = {
            enable = lib.mkEnableOption "Enable element" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.element.enable && isDesktop) {
    home = {
      persistence = {
        "${osConfig.modules.boot.impermanence.persistPath}/${config.home.homeDirectory}" = {
          directories = [".config/Element"];
        };
      };
      packages = [element];
    };
    xdg = {
      desktopEntries = {
        element = {
          name = "Element";
          type = "Application";
          categories = ["Network" "InstantMessaging"];
          exec = "${element}/bin/element-desktop";
          genericName = "A feature-rich client for Matrix.org";
          icon = "${elementIcon}";
          mimeType = ["x-scheme-handler/element"];
        };
      };
    };
  };
}
