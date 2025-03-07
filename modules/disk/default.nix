{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
  inherit (cfg.boot.impermanence) persistPath;
  inherit (cfg.disk) enable device luksDisk cryptStorage vg lvm_volume swapsize;
  inherit (cfg.disk.luks) slot keySize saltLength iterations cipher hash keyFile;
  defaultLuksFormatArgs = ["--cipher=${cipher}" "--hash=${hash}" "--key-size=${builtins.toString keySize}"];
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
        luks = {
          yubikey = lib.mkEnableOption "Enable yubikey luks 2FA PBA" // {default = false;};
          slot = lib.mkOption {
            type = lib.types.int;
            default = 2;
            description = "LUKS key slot number to use for encryption";
          };
          keySize = lib.mkOption {
            type = lib.types.int;
            default = 512;
            description = "Key size in bits for LUKS encryption";
          };
          saltLength = lib.mkOption {
            type = lib.types.int;
            default = 16;
            description = "PBKDF2 salt length in bytes";
          };
          iterations = lib.mkOption {
            type = lib.types.int;
            default = 1000000;
            description = "Number of PBKDF2 iterations for key derivation";
          };
          cipher = lib.mkOption {
            type = lib.types.str;
            default = "aes-xts-plain64";
            description = "Cryptographic cipher to use for disk encryption";
          };
          hash = lib.mkOption {
            type = lib.types.str;
            default = "sha512";
            description = "Hash algorithm for PBKDF2 key derivation";
          };
          keyFile = lib.mkOption {
            type = lib.types.str;
            default = "/tmp/luks.key";
            description = "Temporary key file path for LUKS operations";
          };
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
              partitions = lib.mkIf (!cfg.users.isIso) {
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
                    mountpoint =
                      if (!cfg.disk.luks.yubikey)
                      then "/boot/efi"
                      else "/boot";
                    mountOptions = ["umask=0077"];
                  };
                };
                ${cryptStorage} = lib.mkIf (cfg.disk.luks.yubikey && cfg.security.yubikey.enable) {
                  priority = 3;
                  label = "${cryptStorage}";
                  size = "1M";
                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/crypt";
                    postCreateHook = ''
                      askPassword() {
                        if [ -z ''${IN_DISKO_TEST+x} ]; then
                          set +x
                          echo "Enter password for ${device}: "
                          IFS= read -r -s USER_PASSWORD
                          echo "Enter password for ${device} again to be safe: "
                          IFS= read -r -s USER_PASSWORD_CHECK
                          export USER_PASSWORD
                          [ "$USER_PASSWORD" = "$USER_PASSWORD_CHECK" ]
                          set -x
                        else
                          export USER_PASSWORD=disko
                        fi
                      }

                      until askPassword; do
                        echo "Passwords did not match, please try again."
                      done

                      CRYPT_PARTITION="/dev/disk/by-partlabel/${cryptStorage}"
                      MOUNT_POINT="/mnt/crypt-storage"
                      mkdir -p "$MOUNT_POINT"
                      mount "$CRYPT_PARTITION" "$MOUNT_POINT"
                      mkdir -p "$MOUNT_POINT/crypt-storage"

                      generateLuksKey() {
                        set +x
                        local salt_length
                        local key_length
                        local iterations
                        local salt
                        local challenge
                        local response
                        local luks_key
                        salt_length=${builtins.toString saltLength}
                        key_length=${builtins.toString keySize}
                        iterations=${builtins.toString iterations}
                        salt="$(dd if=/dev/random bs=1 count=$salt_length 2>/dev/null | rbtohex)"
                        challenge="$(echo -n $salt | ${pkgs.openssl}/bin/openssl dgst -binary -sha512 | rbtohex)"
                        response=$(${pkgs.yubikey-personalization}/bin/ykchalresp -${builtins.toString slot} -x $challenge 2>/dev/null)
                        luks_key="$(echo -n $USER_PASSWORD | pbkdf2-sha512 $(($key_length / 8)) $iterations $response | rbtohex)"
                        echo -ne "$salt\n$iterations" > "$MOUNT_POINT/crypt-storage/default"
                        cp "$MOUNT_POINT/crypt-storage/default" "$MOUNT_POINT/crypt-storage/private"
                        cp "$MOUNT_POINT/crypt-storage/default" "$MOUNT_POINT/crypt-storage/${luksDisk}"
                        echo -n "$luks_key" | hextorb > "${keyFile}"
                        set -x
                      }

                      generateLuksKey

                      umount "$MOUNT_POINT"
                      rmdir "$MOUNT_POINT"
                    '';
                  };
                };
                public = lib.mkIf (cfg.airgap.enable) {
                  priority = 4;
                  size = "256M";
                  label = "public";
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
                  label = "private";
                  content = {
                    name = "private";
                    type = "luks";
                    askPassword = !(cfg.disk.luks.yubikey && cfg.security.yubikey.enable);
                    settings = {
                      keyFile =
                        if (cfg.disk.luks.yubikey && cfg.security.yubikey.enable)
                        then keyFile
                        else null;
                      allowDiscards = true;
                    };
                    extraFormatArgs =
                      if (cfg.disk.luks.yubikey && cfg.security.yubikey.enable)
                      then defaultLuksFormatArgs
                      else defaultLuksFormatArgs ++ ["--pbkdf argon2id"];
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
                    askPassword = !(cfg.disk.luks.yubikey && cfg.security.yubikey.enable);
                    settings = {
                      keyFile =
                        if (cfg.disk.luks.yubikey && cfg.security.yubikey.enable)
                        then keyFile
                        else null;
                      allowDiscards = true;
                    };
                    extraFormatArgs =
                      if (cfg.disk.luks.yubikey && cfg.security.yubikey.enable)
                      then defaultLuksFormatArgs
                      else defaultLuksFormatArgs ++ ["--pbkdf argon2id"];
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
                  subvolumes = let
                    rootSubvol = {
                      mountpoint = "/";
                      mountOptions = ["subvol=root" "compress=zstd" "noatime"];
                    };
                    bootSubvol = {
                      mountpoint = "/boot";
                      mountOptions = ["subvol=boot" "compress=zstd" "noatime"];
                    };
                    logSubvol = {
                      mountpoint = "/var/log";
                      mountOptions = ["subvol=logs" "compress=zstd" "noatime"];
                    };
                    snapshotSubvol = {
                      mountpoint = "/snapshots";
                      mountOptions = ["subvol=snapshots" "compress=zstd" "noatime"];
                    };
                    nixSubvol = {
                      mountpoint = "/nix";
                      mountOptions = ["subvol=nix" "compress=zstd" "noatime"];
                    };
                    persistSubvol = {
                      mountpoint = "${persistPath}";
                      mountOptions = ["subvol=persist" "compress=zstd" "noatime"];
                    };
                    swapSubvol = {
                      mountpoint = "/swap";
                      swap = {
                        swapfile = {
                          size = "${builtins.toString swapsize}G";
                        };
                      };
                    };
                  in
                    if (!cfg.disk.luks.yubikey && !cfg.boot.libreboot)
                    then {
                      "/root" = rootSubvol;
                      "/var/log" = logSubvol;
                      "/snapshots" = snapshotSubvol;
                      "/nix" = nixSubvol;
                      "${persistPath}" = persistSubvol;
                      "/swap" = lib.mkIf (!config.modules.airgap.enable) swapSubvol;
                    }
                    else {
                      "/root" = rootSubvol;
                      "/boot" = bootSubvol;
                      "/var/log" = logSubvol;
                      "/snapshots" = snapshotSubvol;
                      "/nix" = nixSubvol;
                      "${persistPath}" = persistSubvol;
                      "/swap" = lib.mkIf (!config.modules.airgap.enable) swapSubvol;
                    };
                };
              };
            };
          };
        };
      };
    };
    boot = lib.mkIf cfg.security.yubikey.enable {
      initrd = lib.mkIf (!cfg.users.isIso) {
        kernelModules = ["vfat" "nls_cp437" "nls_iso8859-1" "usbhid"];
        luks = {
          yubikeySupport = cfg.disk.luks.yubikey && cfg.security.yubikey.enable;
          devices = let
            inherit (cfg.disk) luksDisk cryptStorage;
            mkYubikey = partition: {
              inherit slot saltLength;
              twoFactor = true;
              gracePeriod = 60;
              keyLength = keySize / 8;
              storage = {
                device = "/dev/disk/by-partlabel/${cryptStorage}";
                fsType = "vfat";
                path = "/crypt-storage/${partition}";
              };
            };
          in {
            ${luksDisk} = let
              yubikey = mkYubikey luksDisk;
            in {
              device = "/dev/disk/by-partlabel/${luksDisk}";
              inherit yubikey;
            };
            private = let
              yubikey = mkYubikey "private";
            in
              lib.mkIf (cfg.airgap.enable) {
                device = "/dev/disk/by-partlabel/private";
                inherit yubikey;
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
