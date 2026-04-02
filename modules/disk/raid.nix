{
  inputs,
  lib,
  ...
}:
{ config, ... }:
let
  cfg = config.modules.disk.raid;
  diskEntries = lib.listToAttrs (
    map (dev: {
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
    }) cfg.devices
  );
in
{
  imports = [ inputs.disko.nixosModules.default ];
  options = {
    modules = {
      disk = {
        raid = {
          enable = lib.mkEnableOption "Enable mdadm RAID array with btrfs on top";
          name = lib.mkOption {
            type = lib.types.str;
            default = "storage";
            description = "Name of the mdadm array (used as /dev/md/<name>)";
          };
          devices = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "Block devices to include in the array (e.g. [\"/dev/sda\" \"/dev/sdb\"])";
            example = [
              "/dev/sda"
              "/dev/sdb"
              "/dev/sdc"
              "/dev/sdd"
            ];
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
            default = [
              "compress=zstd"
              "noatime"
              "defaults"
            ];
            description = "btrfs mount options";
          };
        };
      };
    };
  };
  config = lib.mkIf (config.modules.enable && cfg.enable) {
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
            extraArgs = [
              "-L"
              cfg.name
              "-f"
            ];
          };
        };
      };
    };
    boot = {
      swraid = {
        enable = true;
        mdadmConf = "MAILADDR root";
      };
      kernelModules = [
        (
          if
            builtins.elem cfg.level [
              4
              5
              6
            ]
          then
            "raid456"
          else
            "raid${builtins.toString cfg.level}"
        )
        "md_mod"
        "btrfs"
      ];
    };
    environment.systemPackages = [ config.boot.swraid.mdadmPackage ];
  };
}
