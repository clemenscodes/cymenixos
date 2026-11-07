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
      configFile = {
        "swayimg/init.lua" = {
          # Load the other images of the opened file's directory so they can be browsed.
          text = ''
            swayimg.imagelist.adjacent = true

            -- Vim keys
            for key, dir in pairs({ h = "prev", k = "prev", l = "next", j = "next", g = "first", ["Shift+g"] = "last" }) do
              swayimg.viewer.on_key(key, function() swayimg.viewer.open(dir) end)
            end
            for key, dir in pairs({ h = "left", j = "down", k = "up", l = "right", g = "first", ["Shift+g"] = "last" }) do
              swayimg.gallery.on_key(key, function() swayimg.gallery.select(dir) end)
            end
            swayimg.viewer.on_key("q", function() swayimg.exit() end)
            swayimg.gallery.on_key("q", function() swayimg.exit() end)
          '';
        };
      };
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
