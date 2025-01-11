{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
  inherit (cfg.users) user;
in {
  imports = [
    (import ./bluetooth {inherit inputs pkgs lib;})
    (import ./dbus {inherit inputs pkgs lib;})
    (import ./dns {inherit inputs pkgs lib;})
    (import ./firewall {inherit inputs pkgs lib;})
    (import ./irc {inherit inputs pkgs lib;})
    (import ./mtr {inherit inputs pkgs lib;})
    (import ./stevenblack {inherit inputs pkgs lib;})
    (import ./torrent {inherit inputs pkgs lib;})
    (import ./upnp {inherit inputs pkgs lib;})
    (import ./vpn {inherit inputs pkgs lib;})
    (import ./wireless {inherit inputs pkgs lib;})
    (import ./wireshark {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      networking = {
        enable = lib.mkEnableOption "Enable networking options" // {default = false;};
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.networking.enable) {
    environment = {
      persistence = {
        ${config.modules.boot.impermanence.persistPath} = {
          directories = ["/etc/NetworkManager/system-connections"];
        };
      };
    };
    networking = {
      hostName = config.modules.hostname.defaultHostname;
      networkmanager = {
        inherit (cfg.networking) enable;
        unmanaged = [
          "*"
          "except:type:wwan"
          "except:type:wifi"
          "except:type:ethernet"
        ];
      };
    };
    users = {
      users = {
        ${user} = {
          extraGroups = ["networkmanager"];
        };
      };
    };
  };
  systemd = {
    tmpfiles = {
      rules = [
        "L /var/lib/NetworkManager/secret_key - - - - /persist/var/lib/NetworkManager/secret_key"
        "L /var/lib/NetworkManager/seen-bssids - - - - /persist/var/lib/NetworkManager/seen-bssids"
        "L /var/lib/NetworkManager/timestamps - - - - /persist/var/lib/NetworkManager/timestamps"
      ];
    };
  };
}
