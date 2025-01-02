{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.media.editing;
in {
  options = {
    modules = {
      media = {
        editing = {
          gstreamer = {
            enable = lib.mkEnableOption "Enable gstreamer" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.gstreamer.enable) {
    home = {
      packages = [
        pkgs.gst_all_1.gstreamer
        pkgs.gst_all_1.gstreamermm
        pkgs.gst_all_1.gst-vaapi
        pkgs.gst_all_1.gst-plugins-base
        pkgs.gst_all_1.gst-plugins-ugly
        pkgs.gst_all_1.gst-plugins-good
        pkgs.gst_all_1.gst-plugins-bad
        pkgs.gst_all_1.gst-plugins-rs
        pkgs.gst_all_1.gst-libav
      ];
    };
  };
}
