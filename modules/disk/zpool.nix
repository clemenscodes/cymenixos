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

    networking = {
      inherit (cfg) hostId;
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.mountpoint} ${cfg.permissions} ${cfg.user} ${cfg.group}"
    ];

    # nofail: a missing pool (e.g. before disko has run, or after a drive failure)
    # must never block boot and drop the system into emergency mode.
    fileSystems.${cfg.mountpoint} = {
      options = ["nofail" "x-systemd.device-timeout=10s"];
    };

    boot = {
      # boot.supportedFilesystems is a coercedTo type whose merging behaviour
      # is unreliable when mixing list and attrset definitions across modules.
      # We bypass it entirely: explicitly add the ZFS kernel module package built
      # for the active kernel, and load it via kernelModules.
      kernelModules = ["zfs"];
      extraModulePackages = [config.boot.kernelPackages.zfs_unstable];
      zfs = {
        package = cfg.zfsPackage;
        # Don't force-import root — avoids pulling in a degraded pool on rollback
        forceImportRoot = false;
        extraPools = [cfg.name];
      };
    };

    services.zfs = {
      autoScrub = {
        inherit (cfg.autoScrub) enable interval;
        pools = [cfg.name];
      };
    };
  };
}
