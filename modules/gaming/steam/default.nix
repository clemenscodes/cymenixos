{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.gaming;
  inherit (config.modules.boot.impermanence) persistPath;
  inherit (config.modules.users) user;
in {
  imports = [
    (import ./cs2.nix {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      gaming = {
        steam = {
          enable =
            lib.mkEnableOption "Enable steam"
            // {
              default = false;
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
      # Prevent various Vulkan paths that bypass Hyprland entirely via KMS direct scanout.
      # DXVK_HDR/PROTON_ENABLE_HDR: HDR surfaces trigger KMS overlay allocation on NVIDIA
      #   Blackwell — renders on top of Hyprland, survives workspace switches.
      # DISABLE_GAMESCOPE_WSI: VkLayer_FROG_gamescope_wsi ("XWayland Bypass") is an implicit
      #   Vulkan layer that Steam enables via ENABLE_GAMESCOPE_WSI=1 at game launch. Without
      #   Gamescope running as a nested compositor, the layer writes directly to DRM — Hyprland
      #   never sees the window (confirmed root cause for Battle.net disappearing off-compositor).
      sessionVariables = {
        DXVK_HDR = "0";
        PROTON_ENABLE_HDR = "0";
        DISABLE_GAMESCOPE_WSI = "1";
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
          enable = false;
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
        ];
        extraCompatPackages = [pkgs.proton-ge-bin];
      };
    };
  };
}
