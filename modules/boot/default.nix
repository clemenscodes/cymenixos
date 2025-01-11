{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
  inherit (cfg.boot) biosSupport efiSupport libreboot device hibernation swapResumeOffset;
in {
  imports = [
    (import ./impermanence {inherit inputs pkgs lib;})
    (import ./secureboot {inherit inputs pkgs lib;})
    "${inputs.nixpkgs}/nixos/modules/profiles/qemu-guest.nix"
    "${inputs.nixpkgs}/nixos/modules/profiles/all-hardware.nix"
  ];
  options = {
    modules = {
      boot = {
        enable = lib.mkEnableOption "Enable bootloader" // {default = false;};
        biosSupport = lib.mkEnableOption "Enable BIOS support" // {default = false;};
        efiSupport = lib.mkEnableOption "Enable UEFI support" // {default = false;};
        libreboot = lib.mkEnableOption "Skip installing GRUB, merely generate menuentries to load via libreboots GRUB payload" // {default = false;};
        device = lib.mkOption {
          type = lib.types.str;
          description = "The device to install the bootloader to.";
          example = "/dev/vda";
          default = "nodev";
        };
        hibernation = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Enable hibernation using swap. Do not enable this until you have installed the system onto a disk.
            Calculate the resume offset for btrfs swap on the installed disk using `btrfs inspect-internal map-swapfile -r /swap/swapfile`.
            Then set the option modules.boot.hibernation to true and modules.boot.swapResumeOffset to that value.
          '';
        };
        swapResumeOffset = lib.mkOption {
          type = lib.types.int;
          default = null;
          example = 533760;
          description = "The result of running ${lib.getExe pkgs.btrfs-swap-resume-offset} on an installed system.";
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.boot.enable) {
    boot = {
      kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
      kernelModules = ["tcp_bpr" "v4l2loopback"];
      kernel = {
        sysctl = {
          # The Magic SysRq key is a key combo that allows users connected to the
          # system console of a Linux kernel to perform some low-level commands.
          # Disable it, since we don't need it, and is a potential security concern.
          "kernel.sysrq" = 0;

          ## TCP hardening
          # Prevent bogus ICMP errors from filling up logs.
          "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
          # Reverse path filtering causes the kernel to do source validation of
          # packets received from all interfaces. This can mitigate IP spoofing.
          "net.ipv4.conf.default.rp_filter" = 1;
          "net.ipv4.conf.all.rp_filter" = 1;
          # Do not accept IP source route packets (we're not a router)
          "net.ipv4.conf.all.accept_source_route" = 0;
          "net.ipv6.conf.all.accept_source_route" = 0;
          # Don't send ICMP redirects (again, we're not a router)
          "net.ipv4.conf.all.send_redirects" = 0;
          "net.ipv4.conf.default.send_redirects" = 0;
          # Refuse ICMP redirects (MITM mitigations)
          "net.ipv4.conf.all.accept_redirects" = 0;
          "net.ipv4.conf.default.accept_redirects" = 0;
          "net.ipv4.conf.all.secure_redirects" = 0;
          "net.ipv4.conf.default.secure_redirects" = 0;
          "net.ipv6.conf.all.accept_redirects" = 0;
          "net.ipv6.conf.default.accept_redirects" = 0;
          # Protects against SYN flood attacks
          "net.ipv4.tcp_syncookies" = 1;
          # Incomplete protection again TIME-WAIT assassination
          "net.ipv4.tcp_rfc1337" = 1;

          ## TCP optimization
          # TCP Fast Open is a TCP extension that reduces network latency by packing
          # data in the sender’s initial TCP SYN. Setting 3 = enable TCP Fast Open for
          # both incoming and outgoing connections:
          "net.ipv4.tcp_fastopen" = 3;
          # Bufferbloat mitigations + slight improvement in throughput & latency
          "net.ipv4.tcp_congestion_control" = "bbr";
          "net.core.default_qdisc" = "cake";
        };
      };
      supportedFilesystems = ["btrfs" "vfat"];
      tmp = {
        useTmpfs = lib.mkDefault true;
        cleanOnBoot = lib.mkDefault (!config.boot.tmp.useTmpfs);
      };
      loader = lib.mkIf (!cfg.boot.secureboot.enable) {
        efi = {
          efiSysMountPoint =
            if efiSupport
            then "/boot/efi"
            else "/boot";
          canTouchEfiVariables = lib.mkForce false;
        };
        grub = {
          inherit efiSupport device;
          enable = lib.mkForce true;
          enableCryptodisk = true;
          copyKernels = true;
          efiInstallAsRemovable = false;
          fsIdentifier = "label";
          gfxmodeBios = "1920x1080x32,1920x1080x24,1024x768x32,1024x768x24,auto";
          gfxmodeEfi = "1920x1080x32,1920x1080x24,1024x768x32,1024x768x24,auto";
          extraGrubInstallArgs = ["--modules=part_gpt btrfs luks2 cryptodisk gcry_rijndael gcry_sha256 gcry_sha512 pbkdf2 argon2"];
          extraFiles = lib.mkIf (!libreboot) {
            "grub/${pkgs.grub2.grubTarget}/argon2.mod" = lib.mkIf biosSupport "${pkgs.grub2}/lib/grub/${pkgs.grub2.grubTarget}/argon2.mod";
            "grub/${pkgs.grub2.grubTarget}/argon2.module" = lib.mkIf biosSupport "${pkgs.grub2}/lib/grub/${pkgs.grub2.grubTarget}/argon2.module";
            "grub/${pkgs.grub2_efi.grubTarget}/argon2.mod" = lib.mkIf efiSupport "${pkgs.grub2_efi}/lib/grub/${pkgs.grub2_efi.grubTarget}/argon2.mod";
            "grub/${pkgs.grub2_efi.grubTarget}/argon2.module" = lib.mkIf efiSupport "${pkgs.grub2_efi}/lib/grub/${pkgs.grub2_efi.grubTarget}/argon2.module";
          };
          mirroredBoots = lib.mkForce [
            {
              path = "/boot";
              devices = [
                (lib.mkIf (biosSupport || libreboot) device)
                (lib.mkIf efiSupport "nodev")
              ];
              inherit (config.boot.loader.efi) efiSysMountPoint;
            }
          ];
        };
      };
      kernelParams = lib.mkIf hibernation [
        "resume_offset=${builtins.toString swapResumeOffset}"
      ];
      resumeDevice = lib.mkIf hibernation "/dev/disk/by-label/nixos";
      consoleLogLevel = lib.mkDefault 0;
      initrd = {
        verbose = false;
        availableKernelModules = [
          "ohci_pci"
          "ohci_hcd"
          "ehci_pci"
          "ehci_hcd"
          "xhci_pci"
          "xhci_hcd"
          "uas"
          "usb_storage"
          "usbhid"
          "ahci"
          "nvme"
          "sr_mod"
          "aesni_intel"
          "cryptd"
        ];
      };
      extraModulePackages = [config.boot.kernelPackages.v4l2loopback.out];
      extraModprobeConfig = ''
        options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
      '';
    };
  };
}
