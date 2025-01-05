{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
  inherit (cfg.boot) efiSupport device;
in {
  imports = [
    (import ./secureboot {inherit inputs pkgs lib;})
    (import ./luks {inherit inputs pkgs lib;})
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
      supportedFilesystems = ["ext4" "ntfs" "exfat" "btrfs"];
      loader = lib.mkIf (!cfg.boot.secureboot.enable) {
        grub = {
          enable = lib.mkForce true;
          inherit efiSupport device;
          efiInstallAsRemovable = true;
          enableCryptodisk = true;
          copyKernels = true;
          gfxmodeBios = "1920x1080x32,1920x1080x24,1024x768x32,1024x768x24,auto";
          gfxmodeEfi = "1920x1080x32,1920x1080x24,1024x768x32,1024x768x24,auto";
          mirroredBoots = [
            {
              path = "/boot";
              devices = [device];
            }
          ];
        };
      };
      kernelModules = [
        "kvm-intel"
        "kvm-amd"
        "v4l2loopback"
      ];
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
      extraModulePackages = [config.boot.kernelPackages.v4l2loopback.out];
      extraModprobeConfig = ''
        options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
      '';
    };
  };
}
