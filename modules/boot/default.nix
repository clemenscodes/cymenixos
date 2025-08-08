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
      supportedFilesystems = lib.mkForce ["btrfs" "vfat" "reiserfs" "f2fs" "xfs" "ntfs" "cifs"];
      kernelModules = ["v4l2loopback"];
      kernelPackages = lib.mkForce pkgs.linuxPackages_cachyos;
      kernelParams = lib.mkIf hibernation ["resume_offset=${builtins.toString swapResumeOffset}"];
      resumeDevice = lib.mkIf hibernation "/dev/disk/by-label/nixos";
      consoleLogLevel = lib.mkDefault 0;
      extraModulePackages = with config.boot.kernelPackages; [
        v4l2loopback.out
        (rtw88.overrideAttrs (oldAttrs: {
          src = pkgs.fetchFromGitHub {
            owner = "clemenscodes";
            repo = "rtw88";
            rev = "33c6239c5a2f8a0aa85cf698cf86fb7929e57a2b";
            hash = "sha256-p9GXUfE/pp1kUXULYWEvN/L1ie4pebmd2keigBybHqg=";
          };
        }))
      ];
      extraModprobeConfig = ''
        options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
      '';
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
      loader = lib.mkIf (!cfg.boot.secureboot.enable) {
        efi = {
          efiSysMountPoint =
            if (efiSupport && !cfg.disk.luks.yubikey)
            then "/boot/efi"
            else "/boot";
          canTouchEfiVariables = lib.mkForce false;
        };
        grub = {
          inherit efiSupport device;
          enable = lib.mkForce true;
          enableCryptodisk = true;
          copyKernels = true;
          efiInstallAsRemovable = efiSupport;
          gfxmodeBios = "1920x1080x32,1920x1080x24,1024x768x32,1024x768x24,auto";
          gfxmodeEfi = "1920x1080x32,1920x1080x24,1024x768x32,1024x768x24,auto";
          extraGrubInstallArgs = ["--modules=part_gpt btrfs luks2 cryptodisk gcry_rijndael gcry_sha256 gcry_sha512 pbkdf2 argon2"];
          extraFiles = lib.mkIf (!libreboot) {
            "grub/${pkgs.grub2.grubTarget}/argon2.mod" = lib.mkIf biosSupport "${pkgs.grub2}/lib/grub/${pkgs.grub2.grubTarget}/argon2.mod";
            "grub/${pkgs.grub2.grubTarget}/argon2.module" = lib.mkIf biosSupport "${pkgs.grub2}/lib/grub/${pkgs.grub2.grubTarget}/argon2.module";
            "grub/${pkgs.grub2_efi.grubTarget}/argon2.mod" = lib.mkIf efiSupport "${pkgs.grub2_efi}/lib/grub/${pkgs.grub2_efi.grubTarget}/argon2.mod";
            "grub/${pkgs.grub2_efi.grubTarget}/argon2.module" = lib.mkIf efiSupport "${pkgs.grub2_efi}/lib/grub/${pkgs.grub2_efi.grubTarget}/argon2.module";
          };
          mirroredBoots = lib.mkIf (!cfg.disk.luks.yubikey) (lib.mkForce [
            {
              path =
                if !cfg.disk.luks.yubikey && efiSupport
                then "/boot/efi"
                else "/boot";
              devices = [
                (lib.mkIf (biosSupport || libreboot) device)
                (lib.mkIf efiSupport "nodev")
              ];
              inherit (config.boot.loader.efi) efiSysMountPoint;
            }
          ]);
        };
      };
    };
  };
}
