{
  inputs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
  luksCfg = {
    type = "luks";
    askPassword = true;
    settings = {
      allowDiscards = false;
    };
    extraFormatArgs = ["--pbkdf argon2id"];
    extraOpenArgs = ["--timeout 60"];
  };
  inherit (cfg.disk) enable device luksDisk swapsize;
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
        luksDisk = lib.mkOption {
          type = lib.types.str;
          description = "The name of the luks disk";
          default = "luks";
          example = "root";
        };
        swapsize = lib.mkOption {
          type = lib.types.int;
          description = "The size for the swapfile in G";
          default = 16;
          example = 64;
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && enable) {
    disko = {
      devices = {
        disk = {
          main = {
            device = lib.mkDefault device;
            type = "disk";
            content = {
              type = "gpt";
              efiGptPartitionFirst = false;
              partitions = {
                # bios = {
                #   priority = 1;
                #   type = "EF02";
                #   size = "1M";
                #   label = "bios";
                #   content = {
                #     inherit (luksCfg) type askPassword settings extraFormatArgs extraOpenArgs;
                #     name = "${luksDisk}-bios";
                #     content = {
                #       type = "filesystem";
                #       format = "vfat";
                #       mountpoint = null;
                #     };
                #   };
                #   hybrid = {
                #     mbrPartitionType = "0x0c";
                #     mbrBootableFlag = false;
                #   };
                # };
                # efi = {
                #   priority = 2;
                #   label = "efi";
                #   type = "EF00";
                #   size = "512M";
                #   content = {
                #     inherit (luksCfg) type askPassword settings extraFormatArgs extraOpenArgs;
                #     name = "${luksDisk}-efi";
                #     content = {
                #       type = "filesystem";
                #       format = "vfat";
                #       mountpoint = "/boot";
                #       mountOptions = ["umask=0077"];
                #     };
                #   };
                # };
                luks = {
                  size = "100%";
                  label = "luks";
                  type = "8309"; # Linux LUKS partition type
                  content = {
                    name = luksDisk;
                    inherit (luksCfg) type askPassword settings extraFormatArgs extraOpenArgs;
                    content = {
                      type = "btrfs";
                      extraArgs = ["-L" "nixos" "-f"];
                      subvolumes = {
                        "/" = {
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
                              size = "${builtins.toString swapsize}G";
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
    };
    fileSystems = {
      "/var/log" = {
        neededForBoot = true;
      };
      "/persist" = {
        neededForBoot = true;
      };
    };
  };
}
