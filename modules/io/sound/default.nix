{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.io;
  inherit (config.modules.users) user;
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
    users = {
      users = {
        ${user} = {
          extraGroups = ["audio" "sound"];
        };
      };
    };
    home-manager = lib.mkIf (config.modules.home-manager.enable) {
      users = {
        ${user} = {
          home = {
            packages = [pkgs.pwvucontrol];
          };
        };
      };
    };
  };
}
