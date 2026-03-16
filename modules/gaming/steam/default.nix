{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.gaming;
  inherit (config.modules.boot.impermanence) persistPath;
  inherit (config.modules.users) user;
in {
  options = {
    modules = {
      gaming = {
        steam = {
          enable = lib.mkEnableOption "Enable steam" // {default = false;};
          gamescope = {
            fpsLimit = lib.mkOption {
              type = lib.types.int;
              default = 120;
              description = ''
                Gamescope composite output framerate cap (-r).
                Match this to your OBS recording FPS for frame-perfect capture.
                With DLSS FG the engine renders at half this rate; gamescope sees
                the post-FG output so the cap applies to the final presented frames.
              '';
            };
            vrr = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable adaptive sync / VRR in the gamescope session (--adaptive-sync).";
            };
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.steam.enable) {
    home-manager = lib.mkIf config.modules.home-manager.enable {
      users = {
        ${config.modules.users.user} = {
          home = {
            persistence = lib.mkIf (config.modules.boot.enable) {
              "${persistPath}" = {
                directories = [".local/share/Steam"];
              };
            };
          };
        };
      };
    };
    environment = {
      persistence = lib.mkIf (config.modules.boot.enable) {
        ${persistPath} = {
          users = {
            ${user} = {
              directories = [".steam"];
            };
          };
        };
      };
    };
    programs = {
      steam = {
        inherit (cfg.steam) enable;
        package = pkgs.steam;
        protontricks = {
          inherit (cfg.steam) enable;
        };
        gamescopeSession = {
          inherit (cfg.steam) enable;
          env = {
            DXVK_HDR = "1";
            ENABLE_GAMESCOPE_WSI = "1";
          };
          args =
            [
              "--hdr-enabled"
              "--hdr-itm-enable"
              # Cap composite output to match OBS recording FPS.
              # Ensures every captured frame is a real rendered/FG frame —
              # no duplicates from game running faster than capture rate.
              "-r ${toString cfg.steam.gamescope.fpsLimit}"
            ]
            ++ lib.optionals cfg.steam.gamescope.vrr [
              "--adaptive-sync"
            ];
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
        extraPackages = [
          pkgs.libxcursor
          pkgs.libxi
          pkgs.libxinerama
          pkgs.libxscrnsaver
          pkgs.libpng
          pkgs.libpulseaudio
          pkgs.libvorbis
          pkgs.stdenv.cc.cc.lib
          pkgs.libkrb5
          pkgs.keyutils
          pkgs.mangohud
          pkgs.gamescope
          pkgs.gamescope-wsi
        ];
        extraCompatPackages = [pkgs.proton-ge-bin];
      };
    };
  };
}
