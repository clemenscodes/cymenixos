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
          mirroredBoots = [
            {
              path = "/boot";
              devices = [device];
            }
          ];
        };
      };
      extraModulePackages = [config.boot.kernelPackages.v4l2loopback.out];
      kernelModules = ["v4l2loopback"];
      extraModprobeConfig = ''
        options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
      '';
    };
  };
}
