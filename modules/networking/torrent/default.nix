{
  pkgs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.networking;
  # Mullvad's DNS (194.242.2.x) only resolves through the tunnel, and glibc queries
  # only the first 3 nameservers (MAXNS=3). Listing Mullvad servers first meant that
  # with the VPN down every lookup timed out on dead servers for ~60s and never
  # reached a reachable fallback. Keep a reachable public resolver in the first slots;
  # when connected Mullvad still prepends 100.64.0.63, so ad-blocking is unaffected.
  nameservers = [
    "1.1.1.1"
    "8.8.4.4"
    "194.242.2.2"
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
