{lib, ...}: {config, ...}: let
  cfg = config.modules.media.video;
in {
  options = {
    modules = {
      media = {
        video = {
          mpris = {
            enable = lib.mkEnableOption "Enable mpris" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.mpris.enable) {
    services = {
      mpd-mpris = {
        inherit (cfg.mpris) enable;
      };
    };
  };
}
