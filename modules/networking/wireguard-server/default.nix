{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.networking;
  wg = cfg.wireguard-server;
  ip = "${pkgs.iproute2}/bin/ip";
  wgbin = "${pkgs.wireguard-tools}/bin/wg";
in {
  options = {
    modules = {
      networking = {
        wireguard-server = {
          enable = lib.mkEnableOption "Enable a self-hosted WireGuard server" // {default = false;};
          listenPort = lib.mkOption {
            type = lib.types.port;
            default = 51820;
            description = "UDP port the WireGuard server listens on.";
          };
          address = lib.mkOption {
            type = lib.types.str;
            default = "10.100.0.1/24";
            description = "Server address on the WireGuard mesh subnet.";
          };
          privateKeyFile = lib.mkOption {
            type = lib.types.path;
            description = "Path to the server's WireGuard private key (e.g. a SOPS secret path).";
          };
          peers = lib.mkOption {
            type = lib.types.listOf (lib.types.submodule {
              options = {
                publicKey = lib.mkOption {
                  type = lib.types.str;
                  description = "Peer public key (not secret).";
                };
                allowedIPs = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  description = "Mesh IPs routed to this peer, e.g. [\"10.100.0.2/32\"].";
                };
              };
            });
            default = [];
            description = "WireGuard peers (e.g. the phone).";
          };
          bypassVpn = {
            enable = lib.mkEnableOption "Route WG transport around a conflicting full-tunnel VPN" // {default = false;};
            interface = lib.mkOption {
              type = lib.types.str;
              description = "Physical interface to send WG transport packets out of.";
            };
            gateway = lib.mkOption {
              type = lib.types.str;
              description = "LAN gateway for the physical interface.";
            };
            fwMark = lib.mkOption {
              type = lib.types.int;
              default = 51;
              description = "Firewall mark applied to WG transport packets.";
            };
            table = lib.mkOption {
              type = lib.types.int;
              default = 1000;
              description = "Routing table holding the bypass default route.";
            };
            priority = lib.mkOption {
              type = lib.types.int;
              default = 5000;
              description = "ip rule priority (must be below the other VPN's redirect rule).";
            };
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && wg.enable) {
    networking = {
      firewall = {
        allowedUDPPorts = [wg.listenPort];
      };
      wireguard = {
        interfaces = {
          wg0 = {
            ips = [wg.address];
            inherit (wg) listenPort;
            privateKeyFile = toString wg.privateKeyFile;
            peers =
              map (p: {
                inherit (p) publicKey allowedIPs;
              })
              wg.peers;
            postSetup = lib.mkIf wg.bypassVpn.enable ''
              ${wgbin} set wg0 fwmark ${toString wg.bypassVpn.fwMark}
              ${ip} route replace default via ${wg.bypassVpn.gateway} dev ${wg.bypassVpn.interface} table ${toString wg.bypassVpn.table}
              ${ip} rule add fwmark ${toString wg.bypassVpn.fwMark} table ${toString wg.bypassVpn.table} priority ${toString wg.bypassVpn.priority} || true
            '';
            postShutdown = lib.mkIf wg.bypassVpn.enable ''
              ${ip} rule del fwmark ${toString wg.bypassVpn.fwMark} table ${toString wg.bypassVpn.table} priority ${toString wg.bypassVpn.priority} || true
              ${ip} route del default via ${wg.bypassVpn.gateway} dev ${wg.bypassVpn.interface} table ${toString wg.bypassVpn.table} || true
            '';
          };
        };
      };
    };
  };
}
