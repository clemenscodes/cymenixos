{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.media;
in {
  imports = [
    (import ./backgroundremover {inherit inputs pkgs lib;})
    (import ./davinci {inherit inputs pkgs lib;})
    (import ./gimp {inherit inputs pkgs lib;})
    (import ./gstreamer {inherit inputs pkgs lib;})
    (import ./handbrake {inherit inputs pkgs lib;})
    (import ./inkscape {inherit inputs pkgs lib;})
    (import ./kdenlive {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      media = {
        editing = {
          enable = lib.mkEnableOption "Enable editing modules" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.editing.enable) {
    home = {
      packages = [
        pkgs.ffmpeg
        pkgs.x264
        pkgs.x265
      ];
    };
  };
}
