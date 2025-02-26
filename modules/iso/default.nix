{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
in {
  imports = ["${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"];
  options = {
    modules = {
      iso = {
        enable = lib.mkEnableOption "Enable ISO image" // {default = false;};
        fast = lib.mkEnableOption "Use fast compression" // {default = false;};
      };
    };
  };
  config = lib.mkIf cfg.iso.enable {
    isoImage = lib.mkIf cfg.iso.fast {
      squashfsCompression = "gzip -Xcompression-level 1";
    };
    system = {
      build = {
        isoImage = lib.mkForce (
          pkgs.callPackage ./make-iso9660-image.nix
          ({
              inherit (config.isoImage) compressImage volumeID contents;
              isoName = "${config.image.baseName}.iso";
              bootable = config.isoImage.makeBiosBootable;
              bootImage = "/isolinux/isolinux.bin";
              syslinux =
                if config.isoImage.makeBiosBootable
                then pkgs.syslinux
                else null;
              squashfsContents = config.isoImage.storeContents;
              squashfsCompression = config.isoImage.squashfsCompression;
            }
            // lib.optionalAttrs (config.isoImage.makeUsbBootable && config.isoImage.makeBiosBootable) {
              usbBootable = true;
              isohybridMbrImage = "${pkgs.syslinux}/share/syslinux/isohdpfx.bin";
            }
            // lib.optionalAttrs config.isoImage.makeEfiBootable {
              efiBootable = true;
              efiBootImage = "boot/efi.img";
            })
        );
      };
      installer = {
        channel = {
          enable = false;
        };
      };
    };
    modules = {
      users = {
        isIso = true;
      };
      networking = {
        enable = true;
        dbus = {
          enable = true;
        };
        firewall = {
          enable = true;
        };
        wireless = {
          enable = true;
        };
      };
    };
    home-manager = {
      users = {
        ${config.modules.users.user} = {
          modules = {
            networking = {
              enable = true;
              nm = {
                enable = true;
              };
            };
          };
        };
      };
    };
  };
}
