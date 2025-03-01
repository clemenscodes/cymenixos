{
  inputs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.networking;
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [
      (final: prev: {
        mullvad = prev.mullvad.overrideAttrs (oldAttrs: rec {
          version = "2025.4";
          src = prev.fetchFromGitHub {
            owner = "mullvad";
            repo = "mullvadvpn-app";
            rev = version;
            fetchSubmodules = true;
            hash = pkgs.lib.fakeSha256;
          };
          cargoHash = "sha256-EJ8yk11H1QB+7CGjJYY5BjBAFTDK4d02/DJOQTVGFho=";
        });
      })
    ];
  };
  nameservers = [
    "194.242.2.2"
    "194.242.2.3"
    "194.242.2.4"
    "194.242.2.5"
    "194.242.2.6"
    "194.242.2.9"
  ];
in {
  options = {
    modules = {
      networking = {
        torrent = {
          enable = lib.mkEnableOption "Use mullvad DNS" // {default = false;};
          mullvadAccountSecretPath = lib.mkOption {
            type = lib.types.path;
          };
          mullvadDns = lib.mkEnableOption "Use mullvad DNS" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.torrent.enable) {
    environment = {
      persistence = {
        ${config.modules.boot.impermanence.persistPath} = {
          directories = [
            "/etc/mullvad-vpn"
          ];
          users = {
            ${config.modules.users.user} = {
              directories = [
                ".config/Mullvad VPN"
                ".config/qBittorrent"
              ];
            };
          };
        };
      };
    };
    networking = lib.mkIf (cfg.torrent.mullvadDns) {
      inherit nameservers;
    };
    services = {
      mullvad-vpn = {
        inherit (cfg.torrent) enable;
        package = pkgs.mullvad-vpn;
      };
    };
    systemd = {
      services = {
        mullvad-daemon = {
          postStart = let
            mullvad = config.services.mullvad-vpn.package;
          in ''
            while ! ${mullvad}/bin/mullvad status >/dev/null; do sleep 1; done
            account="$(${pkgs.bat}/bin/bat ${cfg.torrent.mullvadAccountSecretPath} --style=plain)"
            # only login if we're not already logged in otherwise we'll get a new device
            current_account="$(${mullvad}/bin/mullvad account get | grep "account:" | sed 's/.* //')"
            if [[ "$current_account" != "$account" ]]; then
              ${mullvad}/bin/mullvad account login "$account"
            fi
            ${mullvad}/bin/mullvad auto-connect set on
            ${mullvad}/bin/mullvad dns set default \
                --block-ads --block-trackers --block-malware --block-gambling --block-adult-content --block-social-media
            # disconnect/reconnect is dirty hack to fix mullvad-daemon not reconnecting after a suspend
            ${mullvad}/bin/mullvad disconnect
            sleep 0.1
            ${mullvad}/bin/mullvad connect
          '';
        };
      };
    };
    environment = {
      systemPackages = with pkgs; [
        wireguard-tools
        qbittorrent
        mullvad
        mullvad-vpn
      ];
    };
  };
}
