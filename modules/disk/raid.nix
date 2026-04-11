{
  inputs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.disk.raid;
  raidModule =
    if builtins.elem cfg.level [4 5 6]
    then "raid456"
    else "raid${builtins.toString cfg.level}";
  diskEntries = lib.listToAttrs (map (dev: {
      name = builtins.baseNameOf dev;
      value = {
        type = "disk";
        device = dev;
        content = {
          type = "gpt";
          partitions = {
            raid = {
              size = "100%";
              content = {
                type = "mdraid";
                name = cfg.name;
              };
            };
          };
        };
      };
    })
    cfg.devices);
in {
  options = {
    modules = {
      disk = {
        raid = {
          enable = lib.mkEnableOption "Enable mdadm RAID array with btrfs on top";
          name = lib.mkOption {
            type = lib.types.str;
            default = "storage";
            description = "Name of the mdadm array (used as /dev/md/<name> and btrfs label)";
          };
          devices = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "Block devices to include in the array";
            example = ["/dev/sda" "/dev/sdb" "/dev/sdc" "/dev/sdd"];
          };
          level = lib.mkOption {
            type = lib.types.int;
            default = 5;
            description = "RAID level (0, 1, 5, 6, 10)";
          };
          mountpoint = lib.mkOption {
            type = lib.types.str;
            default = "/mnt/raid";
            description = "Where to mount the btrfs filesystem";
          };
          mountOptions = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = ["compress=zstd" "noatime" "nofail" "x-systemd.device-timeout=10s"];
            description = "btrfs mount options — nofail ensures a degraded/missing array never prevents boot";
          };
          user = lib.mkOption {
            type = lib.types.str;
            default = "root";
            description = "Owner of the mountpoint directory";
          };
          group = lib.mkOption {
            type = lib.types.str;
            default = "users";
            description = "Group of the mountpoint directory";
          };
          mode = lib.mkOption {
            type = lib.types.str;
            default = "0775";
            description = "Permissions of the mountpoint directory";
          };
        };
      };
    };
  };
  config = lib.mkIf (config.modules.enable && cfg.enable) {
    # Disko owns the full pipeline: partition → mdadm → btrfs format → fileSystems entry.
    # The generated fileSystems entry uses /dev/md/<name>, which works once
    # boot.swraid assembles the array under that name on every boot.
    disko.devices = {
      disk = diskEntries;
      mdadm = {
        ${cfg.name} = {
          type = "mdadm";
          level = cfg.level;
          content = {
            type = "filesystem";
            format = "btrfs";
            mountpoint = cfg.mountpoint;
            mountOptions = cfg.mountOptions;
            extraArgs = ["-L" cfg.name "-f"];
          };
        };
      };
    };

    systemd.tmpfiles.rules = ["d ${cfg.mountpoint} ${cfg.mode} ${cfg.user} ${cfg.group}"];

    boot = {
      swraid = {
        enable = true;
        # HOMEHOST any: assemble arrays regardless of hostname match.
        # This ensures /dev/md/<name> is available before the filesystem mount.
        mdadmConf = ''
          HOMEHOST any
          MAILADDR root
        '';
      };
      kernelModules = [raidModule "md_mod" "btrfs"];
    };
  };
}
