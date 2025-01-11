{
  inputs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
  inherit (cfg.disk) enable device luksDisk swapsize;
  inherit (cfg.boot.impermanence) persistPath;
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
                bios = lib.mkIf (!cfg.boot.libreboot) {
                  priority = 1;
                  type = "EF02";
                  size = "1M";
                  label = "bios";
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
                efi = lib.mkIf cfg.boot.efiSupport {
                  priority = 2;
                  label = "efi";
                  type = "EF00";
                  size = "512M";
                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/boot/efi";
                    mountOptions = ["umask=0077"];
                  };
                };
                luks = {
                  size = "100%";
                  label = "luks";
                  content = {
                    name = luksDisk;
                    type = "luks";
                    askPassword = true;
                    settings = {
                      allowDiscards = false;
                    };
                    extraFormatArgs = ["--pbkdf argon2id"];
                    extraOpenArgs = ["--timeout 60"];
                    content = {
                      type = "lvm_pv";
                      vg = "grubcrypt";
                    };
                  };
                };
              };
            };
          };
        };
        lvm_vg = {
          grubcrypt = {
            type = "lvm_vg";
            lvs = {
              rootvol = {
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = ["-L" "nixos" "-f"];
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = ["subvol=root" "compress=zstd" "noatime"];
                    };
                    "/boot" = {
                      mountpoint = "/boot";
                      mountOptions = ["subvol=boot" "compress=zstd" "noatime"];
                    };
                    "/var/log" = {
                      mountpoint = "/var/log";
                      mountOptions = ["subvol=logs" "compress=zstd" "noatime"];
                    };
                    "/snapshots" = {
                      mountpoint = "/snapshots";
                      mountOptions = ["subvol=snapshots" "compress=zstd" "noatime"];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = ["subvol=nix" "compress=zstd" "noatime"];
                    };
                    "${persistPath}" = {
                      mountpoint = "${persistPath}";
                      mountOptions = ["subvol=persist" "compress=zstd" "noatime"];
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
    services = {
      lvm = {
        enable = true;
      };
      btrbk = {
        instances = {
          btrbk = {
            onCalendar = "hourly";
            settings = {
              timestamp_format = "long";
              snapshot_preserve_min = "1w";
              snapshot_preserve = "4w";
              preserve_day_of_week = "sunday";
              preserve_hour_of_day = "0";
              volume = let
                snapshot_create = "always";
              in {
                "/var/log" = {
                  inherit snapshot_create;
                  subvolume = "/var/log";
                  snapshot_dir = "/snapshots/logs";
                };
                ${persistPath} = {
                  inherit snapshot_create;
                  subvolume = "/persist";
                  snapshot_dir = "/snapshots/persist";
                };
              };
            };
          };
        };
      };
      btrfs = {
        autoScrub = {
          enable = true;
          interval = "weekly";
          fileSystems = ["/"];
        };
      };
    };
    fileSystems = {
      "/var/log" = {
        neededForBoot = true;
      };
      "/snapshots" = {
        neededForBoot = true;
      };
      "${persistPath}" = {
        neededForBoot = true;
      };
    };
    systemd = {
      tmpfiles = {
        rules = [
          "d /snapshots 0755 root root"
          "d /snapshots/persist 0755 root root"
          "d /snapshots/logs 0755 root root"
        ];
      };
    };
  };
}
