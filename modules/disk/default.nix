{
  inputs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
  inherit (cfg.disk) enable device luksDisk cryptStorage vg lvm_volume swapsize;
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
          description = "The name of the luks partition";
          default = "luks";
          example = "root";
        };
        cryptStorage = lib.mkOption {
          type = lib.types.str;
          description = "The name of the crypt storage partition";
          default = "crypt";
          example = "salt";
        };
        vg = lib.mkOption {
          type = lib.types.str;
          description = "The name of the lvm volume group. Defaults to grubcrypt to support libreboot by default";
          default = "grubcrypt";
          example = "root_vg";
        };
        lvm_volume = lib.mkOption {
          type = lib.types.str;
          description = "The name of the main volume in lvm. Defaults to rootvol to support libreboot by default";
          default = "rootvol";
          example = "bootvol";
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
                bios = lib.mkIf (cfg.boot.biosSupport && !cfg.boot.libreboot) {
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
                efi = lib.mkIf (cfg.boot.efiSupport && !cfg.boot.libreboot) {
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
                ${cryptStorage} = lib.mkIf cfg.security.yubikey.enable {
                  priority = 3;
                  label = "${cryptStorage}";
                  size = "4M";
                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/crypt";
                    postCreateHook = ''
                      # Run code here to store the salt on this partition
                      mkdir -p /crypt/crypt-storage
                    '';
                  };
                };
                public = lib.mkIf (cfg.airgap.enable) {
                  priority = 4;
                  size = "256M";
                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/public";
                    mountOptions = ["umask=0000"];
                  };
                };
                private = lib.mkIf (cfg.airgap.enable) {
                  priority = 5;
                  size = "256M";
                  content = {
                    type = "luks";
                    name = "private";
                    askPassword = true;
                    settings = {
                      allowDiscards = true;
                    };
                    postMountHook = "dmsetup ls --target crypt --exec 'cryptsetup close' 2> /dev/null";
                    extraFormatArgs = ["--pbkdf argon2id"];
                    extraOpenArgs = ["--timeout 60"];
                    content = {
                      type = "filesystem";
                      format = "vfat";
                      mountpoint = "/private";
                    };
                  };
                };
                ${luksDisk} = {
                  size = "100%";
                  label = luksDisk;
                  content = {
                    name = luksDisk;
                    type = "luks";
                    askPassword = true;
                    settings = {
                      allowDiscards = false;
                    };
                    postMountHook = "dmsetup ls --target crypt --exec 'cryptsetup close' 2> /dev/null";
                    extraFormatArgs = ["--pbkdf argon2id"];
                    extraOpenArgs = ["--timeout 60"];
                    content = {
                      type = "lvm_pv";
                      inherit vg;
                    };
                  };
                };
              };
            };
          };
        };
        lvm_vg = {
          ${vg} = {
            type = "lvm_vg";
            lvs = {
              ${lvm_volume} = {
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
                    "/swap" = lib.mkIf (!config.modules.airgap.enable) {
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
    boot = lib.mkIf cfg.security.yubikey.enable {
      initrd = {
        kernelModules = ["vfat" "nls_cp437" "nls_iso8859-1" "usbhid"];
        luks = {
          yubikeySupport = cfg.security.yubikey.enable;
          devices = let
            inherit (cfg.disk) luksDisk cryptStorage;
          in {
            ${luksDisk} = {
              device = "/dev/disk/by-partlabel/${luksDisk}";
              yubikey = {
                slot = 2;
                twoFactor = true;
                gracePeriod = 60;
                iterationStep = 0;
                keyLength = 64;
                saltLength = 16;
                storage = {
                  device = "/dev/disk/by-partlabel/${cryptStorage}";
                  fsType = "vfat";
                  path = "/crypt-storage/default";
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
              snapshot_preserve_min = "1d";
              snapshot_preserve = "2d";
              volume = let
                snapshot_create = "always";
              in {
                "/boot" = {
                  inherit snapshot_create;
                  subvolume = "/boot";
                  snapshot_dir = "/snapshots/boots";
                };
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
          "d /snapshots/boots 0755 root root"
        ];
      };
    };
  };
}
