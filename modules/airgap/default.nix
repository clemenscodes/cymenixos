{
  inputs,
  pkgs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules;
  capkgs = inputs.capkgs.packages.${system};
  bech32 = capkgs.bech32-input-output-hk-cardano-node-10-1-4-1f63dbf;
  cardano-address = capkgs.cardano-address-cardano-foundation-cardano-wallet-v2025-01-09-6965d18;
  cardano-cli = capkgs.cardano-cli-input-output-hk-cardano-node-10-1-4-1f63dbf;
  cc-sign = capkgs.cc-sign-IntersectMBO-credential-manager-0-1-2-0-081cc8c;
  orchestrator-cli = capkgs.orchestrator-cli-IntersectMBO-credential-manager-0-1-2-0-081cc8c;
in {
  options = {
    modules = {
      airgap = {
        enable = lib.mkEnableOption "Enable airgap mode" // {default = false;};
        cardano = {
          enable = lib.mkEnableOption "Enable cardano airgap tools" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf config.modules.airgap.enable {
    nix = {
      settings = {
        substituters = lib.mkForce [];
        trusted-users = [cfg.users.user];
      };
    };
    hardware = {
      bluetooth = {
        enable = lib.mkForce false;
      };
    };
    boot = {
      initrd = {
        network = {
          enable = lib.mkForce false;
        };
      };
    };
    networking = {
      firewall = {
        enable = true;
      };
      hostName = lib.mkDefault cfg.hostname.defaultHostname;
      enableIPv6 = lib.mkForce false;
      interfaces = lib.mkForce {};
      useDHCP = lib.mkForce false;
      useNetworkd = lib.mkForce false;
      dhcpcd = {
        enable = lib.mkForce false;
        allowInterfaces = lib.mkForce [];
      };
      resolvconf = {
        enable = lib.mkForce false;
      };
      networkmanager = {
        enable = lib.mkForce false;
      };
      wireless = {
        enable = lib.mkForce false;
      };
    };
    services = {
      ntpd = {
        enable = lib.mkForce false;
      };
      systemd-timesyncd = {
        enable = lib.mkForce false;
      };
      systemd = {
        timedated = {
          enable = lib.mkForce true;
        };
      };
      udev = {
        extraRules = ''
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="1b7c", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="2b7c", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="3b7c", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="4b7c", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="1807", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="1808", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c97", ATTRS{idProduct}=="0000", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c97", ATTRS{idProduct}=="0001", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c97", ATTRS{idProduct}=="0004", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
          KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0660", GROUP="plugdev", ATTRS{idVendor}=="2c97"
          KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0660", GROUP="plugdev", ATTRS{idVendor}=="2581"
          ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="0", ATTR{authorized}="1"
        '';
      };
    };
    environment = {
      systemPackages =
        (with pkgs; [
          cfssl
          cryptsetup
          pgpdump
          paperkey
          rng-tools
          ent
          gnupg
          pcsctools
          jq
          lvm2
          openssl
          pwgen
          usbutils
          util-linux
          disko
        ])
        ++ (
          if config.modules.airgap.cardano.enable
          then [
            bech32
            cardano-address
            cardano-cli
            orchestrator-cli
            cc-sign
          ]
          else []
        );
    };
  };
}
