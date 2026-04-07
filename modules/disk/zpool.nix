{lib, ...}: {
  config,
  pkgs,
  ...
}: let
  cfg = config.modules.disk.zpool;
  diskEntries = lib.listToAttrs (
    map (dev: {
      name = builtins.baseNameOf dev;
      value = {
        type = "disk";
        device = dev;
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = cfg.name;
              };
            };
          };
        };
      };
    }) cfg.devices
  );
  # Modelled on nixos/modules/tasks/filesystems/zfs.nix createImportService.
  # We cannot use boot.zfs.enabled (it requires boot.supportedFilesystems.zfs,
  # whose coercedTo merge silently drops attrset definitions from NixOS modules)
  # so we replicate the essential import logic ourselves.
  importScript = ''
    poolImported() {
      ${cfg.zfsPackage}/sbin/zpool list "$1" >/dev/null 2>&1
    }

    poolReady() {
      local state
      state="$(${cfg.zfsPackage}/sbin/zpool import \
        -d /dev/disk/by-partlabel 2>/dev/null \
        | ${pkgs.gawk}/bin/awk \
          '/pool: ${cfg.name}/ { found=1 }
           /state:/ { if (found==1) { print $2; exit } }
           END { if (!found) print "MISSING" }')"
      [ "$state" = "ONLINE" ]
    }

    if poolImported "${cfg.name}"; then
      echo "Pool ${cfg.name} already imported"
      exit 0
    fi

    echo "Waiting for ZFS pool ${cfg.name}..."
    for i in $(seq 1 60); do
      poolReady "${cfg.name}" && break
      sleep 1
    done

    ${cfg.zfsPackage}/sbin/zpool import \
      -d /dev/disk/by-partlabel -N "${cfg.name}"
  '';
in {
  options = {
    modules = {
      disk = {
        zpool = {
          enable = lib.mkEnableOption "ZFS pool (raidz/mirror) via disko";
          name = lib.mkOption {
            type = lib.types.str;
            default = "storage";
            description = "ZFS pool name — also used as the dataset label";
          };
          mode = lib.mkOption {
            type = lib.types.str;
            default = "raidz2";
            description = "ZFS vdev topology: raidz, raidz2, raidz3, mirror, or empty string for stripe";
            example = "raidz2";
          };
          devices = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "Block devices to include in the pool (minimum 4 for raidz2)";
            example = [
              "/dev/sda"
              "/dev/sdb"
              "/dev/sdc"
              "/dev/sdd"
            ];
          };
          mountpoint = lib.mkOption {
            type = lib.types.str;
            default = "/mnt/raid";
            description = "Mountpoint for the ZFS pool root dataset";
          };
          user = lib.mkOption {
            type = lib.types.str;
            default = config.modules.users.user;
            defaultText = lib.literalExpression "config.modules.users.user";
            description = "Owner of the mountpoint directory";
          };
          group = lib.mkOption {
            type = lib.types.str;
            default = "users";
            description = "Group of the mountpoint directory";
          };
          permissions = lib.mkOption {
            type = lib.types.str;
            default = "0775";
            description = "Permissions of the mountpoint directory";
          };
          ashift = lib.mkOption {
            type = lib.types.int;
            default = 12;
            description = "ZFS ashift — 12 for 4K-sector drives (most modern HDDs/SSDs), 13 for 8K";
          };
          zfsPackage = lib.mkOption {
            type = lib.types.package;
            default = pkgs.zfs_unstable;
            defaultText = lib.literalExpression "pkgs.zfs_unstable";
            description = ''
              ZFS package to use. Defaults to pkgs.zfs_unstable because nixos-unstable
              regularly ships kernels that stable ZFS does not yet support. Override
              with pkgs.zfs once stable catches up to your kernel.
            '';
          };
          hostId = lib.mkOption {
            type = lib.types.str;
            description = ''
              8-character hex host ID required by ZFS to prevent accidental pool
              imports across machines. Generate one with:
                head -c 4 /dev/urandom | od -A n -t x4 | tr -d ' \n'
            '';
            example = "8a7b3c2d";
          };
          autoScrub = {
            enable = lib.mkEnableOption "Periodic ZFS scrub" // {default = true;};
            interval = lib.mkOption {
              type = lib.types.str;
              default = "monthly";
              description = "Systemd calendar expression for scrub frequency";
            };
          };
        };
      };
    };
  };
  config = lib.mkIf (config.modules.enable && cfg.enable) {
    disko.devices = {
      disk = diskEntries;
      zpool = {
        ${cfg.name} = {
          type = "zpool";
          inherit (cfg) mode mountpoint;
          options = {
            ashift = builtins.toString cfg.ashift;
            autotrim = "on";
          };
          rootFsOptions = {
            compression = "zstd";
            atime = "off";
            xattr = "sa";
            acltype = "posixacl";
          };
        };
      };
    };

    environment.systemPackages = [cfg.zfsPackage];

    networking = {
      inherit (cfg) hostId;
    };

    systemd = {
      tmpfiles.rules = [
        # d: create mountpoint before ZFS mounts (nofail scenario)
        "d ${cfg.mountpoint} ${cfg.permissions} ${cfg.user} ${cfg.group}"
        # z: fix dataset root permissions after ZFS mounts (runs after local-fs.target)
        "z ${cfg.mountpoint} ${cfg.permissions} ${cfg.user} ${cfg.group}"
      ];
      services."zfs-import-${cfg.name}" = {
        description = "Import ZFS pool \"${cfg.name}\"";
        wants = ["systemd-udev-settle.service"];
        after = ["systemd-udev-settle.service" "systemd-modules-load.service"];
        before = ["local-fs.target" "shutdown.target"];
        wantedBy = ["local-fs.target"];
        conflicts = ["shutdown.target"];
        unitConfig.DefaultDependencies = "no";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = "yes";
        };
        script = importScript;
      };
    };

    # nofail: a missing pool must never block boot and drop into emergency mode.
    # x-systemd.wants ensures the mount is attempted only after import succeeds.
    fileSystems.${cfg.mountpoint} = {
      options = [
        "nofail"
        "x-systemd.device-timeout=10s"
        "x-systemd.wants=zfs-import-${cfg.name}.service"
        "x-systemd.after=zfs-import-${cfg.name}.service"
      ];
    };

    boot = {
      kernelModules = ["zfs"];
      extraModulePackages = [config.boot.kernelPackages.zfs_unstable];
      zfs = {
        package = cfg.zfsPackage;
        forceImportRoot = false;
        # extraPools kept so zpool.cache is managed if boot.zfs.enabled ever becomes true
        extraPools = [cfg.name];
      };
    };

    services.zfs.autoScrub = {
      inherit (cfg.autoScrub) enable interval;
      pools = [cfg.name];
    };
  };
}
