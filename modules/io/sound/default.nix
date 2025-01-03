{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.io;
in {
  options = {
    modules = {
      io = {
        sound = {
          enable = lib.mkEnableOption "Enable sound services" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.sound.enable) {
    services = {
      pipewire = {
        inherit (cfg.sound) enable;
        audio = {
          inherit (cfg.sound) enable;
        };
        wireplumber = {
          inherit (cfg.sound) enable;
        };
        alsa = {
          inherit (cfg.sound) enable;
          support32Bit = cfg.sound.enable;
        };
        pulse = {
          inherit (cfg.sound) enable;
        };
        jack = {
          inherit (cfg.sound) enable;
        };
      };
    };
    home-manager = lib.mkIf (config.modules.home-manager.enable) {
      users = {
        ${config.modules.users.user} = {
          home = {
            packages = with pkgs; [
              pwvucontrol
            ];
          };
        };
      };
    };
  };
}
