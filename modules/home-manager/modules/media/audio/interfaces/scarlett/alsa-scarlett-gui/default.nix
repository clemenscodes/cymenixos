{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.media.audio.interfaces.scarlett;
in {
  options = {
    modules = {
      media = {
        audio = {
          interfaces = {
            scarlett = {
              alsa-scarlett-gui = {
                enable = lib.mkEnableOption "Enable alsa-scarlett-gui" // {default = false;};
              };
            };
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.alsa-scarlett-gui.enable) {
    home = {
      packages = [pkgs.alsa-scarlett-gui];
    };
  };
}
