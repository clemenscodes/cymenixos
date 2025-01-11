{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.gaming;
in {
  options = {
    modules = {
      gaming = {
        steam = {
          enable = lib.mkEnableOption "Enable steam" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.steam.enable) {
    home-manager = lib.mkIf config.modules.home-manager.enable {
      users = {
        ${config.modules.users.user} = {
          home = {
            persistence = {
              "${config.modules.boot.impermanence.persistPath}${config.home.homeDirectory}" = {
                directories = [
                  {
                    directory = ".local/share/Steam";
                    method = "symlink";
                  }
                ];
              };
            };
          };
        };
      };
    };
    environment = {
      persistence = {
        ${config.modules.boot.impermanence.persistPath} = {
          users = {
            ${config.modules.users.user} = {
              directories = [".steam"];
            };
          };
        };
      };
      systemPackages = [pkgs.steamtinkerlaunch];
    };
    programs = {
      steam = {
        inherit (cfg.steam) enable;
        protontricks = {
          inherit (cfg.steam) enable;
        };
        gamescopeSession = {
          inherit (cfg.gamescope) enable;
        };
        remotePlay = {
          openFirewall = cfg.steam.enable;
        };
        localNetworkGameTransfers = {
          openFirewall = cfg.steam.enable;
        };
        dedicatedServer = {
          openFirewall = cfg.steam.enable;
        };
        extest = {
          inherit (cfg.steam) enable;
        };
        package = pkgs.steam;
        extraPackages = [
          pkgs.xorg.libXcursor
          pkgs.xorg.libXi
          pkgs.xorg.libXinerama
          pkgs.xorg.libXScrnSaver
          pkgs.libpng
          pkgs.libpulseaudio
          pkgs.libvorbis
          pkgs.stdenv.cc.cc.lib
          pkgs.libkrb5
          pkgs.keyutils
        ];
        extraCompatPackages = [pkgs.proton-ge-bin];
      };
    };
  };
}
