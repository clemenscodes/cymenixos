{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.display.lockscreen;
in {
  options = {
    modules = {
      display = {
        lockscreen = {
          sway-audio-idle-inhibit = {
            enable = lib.mkEnableOption "Enable sway-audio-idle-inhibit" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.sway-audio-idle-inhibit.enable) {
    home = {
      packages = [pkgs.sway-audio-idle-inhibit];
    };
  };
}
