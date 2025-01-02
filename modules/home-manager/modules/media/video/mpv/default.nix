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
  };
}
