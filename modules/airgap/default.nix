{
  inputs,
  pkgs,
  lib,
  cymenixos,
  ...
}: {
  self,
  config,
  system,
  ...
}: let
  cfg = config.modules;
  cardanix = inputs.cardanix.packages.${system};
  inherit (cardanix) bech32 cardano-address cardano-cli cc-sign orchestrator-cli;
  flakesClosure = flakes:
    if flakes == []
    then []
    else
      lib.unique (flakes
        ++ flakesClosure (builtins.concatMap (flake:
          if flake ? inputs
          then builtins.attrValues flake.inputs
          else [])
        flakes));
  flakeClosureRef = flake: pkgs.writeText "flake-closure" (builtins.concatStringsSep "\n" (flakesClosure [flake]) + "\n");
  dependencies =
    if cfg.users.isIso
    then [
      config.system.build.diskoScript
      config.system.build.diskoScript.drvPath
      pkgs.stdenv.drvPath
      pkgs.perlPackages.ConfigIniFiles
      pkgs.perlPackages.FileSlurp
      (pkgs.closureInfo {rootPaths = [];}).drvPath
    ]
    else [];
  closureInfo = pkgs.closureInfo {rootPaths = dependencies;};
in {
  options = {
    modules = {
      airgap = {
        enable = lib.mkEnableOption "Enable airgap mode" // {default = false;};
        offline = lib.mkEnableOption "Enable offline building" // {default = false;};
        cardano = {
          enable = lib.mkEnableOption "Enable cardano airgap tools" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf config.modules.airgap.enable {
    system = lib.mkIf cfg.airgap.offline {
      includeBuildDependencies = cfg.airgap.offline;
      extraDependencies = [
        (flakeClosureRef self)
        (flakeClosureRef cymenixos)
      ];
    };
    nix = {
      settings = {
        substituters = lib.mkForce [];
        trusted-users = lib.mkForce [cfg.users.user];
        hashed-mirrors = null;
        connect-timeout = 3;
        flake-registry = lib.mkForce (pkgs.writeText "registry.json" ''{"flakes":[],"version":2}'');
      };
      registry = {
        nixpkgs = {
          to = {};
        };
      };
    };
    nixpkgs = {
      flake = {
        setFlakeRegistry = false;
        setNixPath = false;
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
      timesyncd = {
        enable = lib.mkForce false;
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
      etc = lib.mkIf cfg.airgap.offline {
        install-closure = {
          source = "${closureInfo}/store-paths";
        };
      };
      systemPackages =
        [
          pkgs.cfssl
          pkgs.cryptsetup
          pkgs.pgpdump
          pkgs.paperkey
          pkgs.rng-tools
          pkgs.ent
          pkgs.gnupg
          pkgs.pcsctools
          pkgs.jq
          pkgs.lvm2
          pkgs.openssl
          pkgs.pwgen
          pkgs.usbutils
          pkgs.util-linux
          pkgs.disko
        ]
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
