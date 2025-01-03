{
  inputs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
in {
  imports = [inputs.disko.nixosModules.default];
  options = {
    modules = {
      disk = {
        enable = lib.mkEnableOption "Enable disk configuration" // {default = false;};
        device = lib.mkOption {
          type = lib.types.str;
          description = "The device to install the filesystem on using disko";
          example = "/dev/vda";
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.disk.enable) {
    fileSystems = {
      "/persist" = {
        neededForBoot = true;
      };
      "/var/log" = {
        neededForBoot = true;
      };
    };
    disko = {
      devices = {
        disk = {
          main = {
            device = lib.mkDefault cfg.disk.device;
            type = "disk";
            content = {
              type = "gpt";
              efiGptPartitionFirst = false;
              partitions = {
                bios = {
                  priority = 1;
                  type = "EF02";
                  size = "1M";
                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = null;
                  };
                  hybrid = {
                    mbrPartitionType = "0x0c";
                    mbrBootableFlag = false;
                  };
                };
                efi = {
                  priority = 2;
                  label = "boot";
                  type = "EF00";
                  size = "512M";
                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/boot";
                    mountOptions = ["umask=0077"];
                  };
                };
                luks = {
                  size = "100%";
                  label = "luks";
                  content = {
                    type = "luks";
                    name = "root";
                    askPassword = true;
                    settings = {
                      allowDiscards = false;
                    };
                    content = {
                      type = "lvm_pv";
                      vg = "pool";
                    };
                  };
                };
              };
            };
          };
        };
        lvm_vg = {
          pool = {
            type = "lvm_vg";
            lvs = {
              root = {
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = ["-L" "nixos" "-f"];
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = ["subvol=root" "compress=zstd" "noatime"];
                    };
                    "/home" = {
                      mountpoint = "/home";
                      mountOptions = ["subvol=home" "compress=zstd" "noatime"];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = ["subvol=nix" "compress=zstd" "noatime"];
                    };
                    "/persist" = {
                      mountpoint = "/persist";
                      mountOptions = ["subvol=persist" "compress=zstd" "noatime"];
                    };
                    "/log" = {
                      mountpoint = "/var/log";
                      mountOptions = ["subvol=log" "compress=zstd" "noatime"];
                    };
                    "/swap" = {
                      mountpoint = "/swap";
                      swap = {
                        swapfile = {
                          size = "64G";
                        };
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
