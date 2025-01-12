{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.io;
  inherit (config.modules.users) user;
  inherit (config.modules.boot.impermanence) persistPath;
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
    environment = {
      persistence = {
        ${persistPath} = {
          enable = true;
          hideMounts = true;
          directories = ["/var/lib/pipewire"];
          users = {
            ${user} = {
              directories = [".local/state/wireplumber"];
            };
          };
        };
      };
    };
    boot = {
      extraModprobeConfig = ''
        options snd slots=snd-hda-intel
      '';
      blacklistedKernelModules = ["snd_pcsp"];
    };
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
      pulseaudio = {
        enable = lib.mkForce false;
      };
    };
    programs = {
      dconf = {
        enable = true;
      };
    };
    environment = {
      systemPackages = [
        pkgs.alsa-utils
        pkgs.pavucontrol
        pkgs.easyeffects
        pkgs.pulseaudio
        pkgs.at-spi2-core
      ];
    };
    systemd = {
      user = {
        services = {
          easyeffects = {
            wantedBy = ["graphical-session.target"];
            unitConfig = {
              Description = "Easyeffects daemon";
              Requires = ["dbus.service"];
              After = ["graphical-session-pre.target"];
              PartOf = ["graphical-session.target" "pipewire.service"];
            };
            serviceConfig = {
              ExecStart = "${pkgs.easyeffects}/bin/easyeffects --gapplication-service";
              ExecStop = "${pkgs.easyeffects}/bin/easyeffects --quit";
              Restart = "on-failure";
              RestartSec = 5;
            };
          };
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
