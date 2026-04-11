{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.media.video;
in {
  options = {
    modules = {
      media = {
        video = {
          mpv = {
            enable = lib.mkEnableOption "Enable mpv" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.mpv.enable) {
    programs = {
      mpv = {
        inherit (cfg.mpv) enable;
        package = pkgs.mpv.override {scripts = [pkgs.mpvScripts.mpris];};
        bindings = {
          l = "seek 5";
          h = "seek -5";
          j = "seek -60";
          k = "seek 60";
          S = "cycle sub";
        };
      };
    };
    xdg.mimeApps = {
      defaultApplications = let
        videoTypes = [
          "video/mp4"
          "video/x-matroska"
          "video/webm"
          "video/x-msvideo"
          "video/vnd.avi"
          "video/quicktime"
          "video/mpeg"
          "video/ogg"
          "video/3gpp"
          "video/3gpp2"
          "video/x-flv"
          "video/x-wmv"
          "video/x-ms-wmv"
          "video/x-ogm+ogg"
          "video/x-theora+ogg"
          "video/x-mkv"
        ];
      in
        builtins.listToAttrs (map (mime: {
            name = mime;
            value = ["mpv.desktop"];
          })
          videoTypes);
      associations.removed = let
        videoTypes = [
          "video/mp4"
          "video/x-matroska"
          "video/webm"
          "video/x-msvideo"
          "video/vnd.avi"
          "video/quicktime"
          "video/mpeg"
          "video/ogg"
          "video/3gpp"
          "video/3gpp2"
          "video/x-flv"
          "video/x-wmv"
          "video/x-ms-wmv"
          "video/x-ogm+ogg"
          "video/x-theora+ogg"
          "video/x-mkv"
        ];
        # umpv is a companion script shipped with mpv that reuses a running instance;
        # it registers its own desktop entry but we never want it as a default.
        unwanted = ["umpv.desktop" "brave-browser.desktop" "vlc.desktop"];
      in
        builtins.listToAttrs (map (mime: {
            name = mime;
            value = unwanted;
          })
          videoTypes);
    };
  };
}
