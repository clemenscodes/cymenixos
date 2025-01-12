{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.display.imageviewer;
in {
  options = {
    modules = {
      display = {
        imageviewer = {
          swayimg = {
            enable = lib.mkEnableOption "Enable swayimg" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.swayimg.enable) {
    home = {
      packages = [pkgs.swayimg];
    };
    xdg = {
      desktopEntries = {
        swayimg = {
          name = "Swayimg";
          genericName = "Image Viewer";
          exec = "swayimg %U";
          icon = "swayimg";
          terminal = false;
          mimeType = [
            "image/jpeg"
            "image/png"
            "image/gif"
            "image/webp"
            "image/bmp"
            "image/tiff"
          ];
        };
      };
      mimeApps = {
        associations = {
          added = {
            "image/jpeg" = ["swayimg.desktop"];
            "image/png" = ["swayimg.desktop"];
            "image/gif" = ["swayimg.desktop"];
            "image/webp" = ["swayimg.desktop"];
            "image/bmp" = ["swayimg.desktop"];
            "image/tiff" = ["swayimg.desktop"];
          };
          removed = {
            "image/jpeg" = ["swappy.desktop" "brave-browser.desktop"];
            "image/png" = ["swappy.desktop" "brave-browser.desktop"];
            "image/gif" = ["swappy.desktop" "brave-browser.desktop"];
            "image/webp" = ["swappy.desktop" "brave-browser.desktop"];
            "image/bmp" = ["swappy.desktop" "brave-browser.desktop"];
            "image/tiff" = ["swappy.desktop" "brave-browser.desktop"];
          };
        };
        defaultApplications = {
          "image/jpeg" = ["swayimg.desktop"];
          "image/png" = ["swayimg.desktop"];
          "image/gif" = ["swayimg.desktop"];
          "image/webp" = ["swayimg.desktop"];
          "image/bmp" = ["swayimg.desktop"];
          "image/tiff" = ["swayimg.desktop"];
        };
      };
    };
  };
}
