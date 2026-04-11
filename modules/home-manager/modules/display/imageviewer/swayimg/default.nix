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
            "image/avif"
            "image/heif"
            "image/heic"
            "image/svg+xml"
            "image/x-portable-pixmap"
            "image/x-portable-bitmap"
            "image/x-tga"
          ];
        };
      };
      mimeApps = let
        imageTypes = [
          "image/jpeg"
          "image/png"
          "image/gif"
          "image/webp"
          "image/bmp"
          "image/tiff"
          "image/avif"
          "image/heif"
          "image/heic"
          "image/svg+xml"
          "image/x-portable-pixmap"
          "image/x-portable-bitmap"
          "image/x-tga"
        ];
        unwanted = ["swappy.desktop" "brave-browser.desktop" "gimp.desktop" "org.gimp.GIMP.desktop"];
      in {
        associations = {
          added = builtins.listToAttrs (map (mime: {
              name = mime;
              value = ["swayimg.desktop"];
            })
            imageTypes);
          removed = builtins.listToAttrs (map (mime: {
              name = mime;
              value = unwanted;
            })
            imageTypes);
        };
        defaultApplications = builtins.listToAttrs (map (mime: {
            name = mime;
            value = ["swayimg.desktop"];
          })
          imageTypes);
      };
    };
  };
}
