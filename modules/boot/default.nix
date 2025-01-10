{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
  inherit (cfg.boot) efiSupport device hibernation swapResumeOffset;
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
        efiSupport = lib.mkEnableOption "Enable UEFI" // {default = false;};
        device = lib.mkOption {
          type = lib.types.str;
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
    environment = {
      systemPackages = [
        pkgs.ntfs3g
        pkgs.exfat
        pkgs.gparted
        pkgs.parted
        pkgs.xorg.xhost
      ];
    };
    boot = {
      kernelPackages = lib.mkDefault pkgs.linuxPackages_xanmod_latest;
      initrd = {
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
        ];
      };
      supportedFilesystems = ["btrfs" "vfat"];
      loader = lib.mkIf (!cfg.boot.secureboot.enable) {
        efi = {
          efiSysMountPoint = "/boot/efi";
          canTouchEfiVariables = efiSupport;
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
          extraGrubInstallArgs = ["--modules=nativedisk ahci part_gpt btrfs luks2 cryptodisk gcry_rijndael gcry_sha256 gcry_sha512 pbkdf2"];
          mirroredBoots = lib.mkForce [
            {
              path = "/boot";
              devices = [device];
            }
            (lib.mkIf efiSupport {
              inherit (config.boot.loader.efi) efiSysMountPoint;
              path = "/boot/efi";
              devices = ["nodev"];
            })
          ];
        };
      };
      kernelParams = lib.mkIf hibernation [
        "resume_offset=${builtins.toString swapResumeOffset}"
      ];
      resumeDevice = lib.mkIf hibernation "/dev/disk/by-label/nixos";
      kernelModules = ["v4l2loopback"];
      extraModulePackages = [config.boot.kernelPackages.v4l2loopback.out];
      extraModprobeConfig = ''
        options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
      '';
    };
  };
}
