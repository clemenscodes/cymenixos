{
  inputs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
  inherit (cfg.users) user;
  inherit (cfg.boot.impermanence) persistPath;
in {
  imports = [inputs.impermanence.nixosModules.impermanence];
  options = {
    modules = {
      boot = {
        impermanence = {
          persistPath = lib.mkOption {
            type = lib.types.str;
            description = "Where the persistent subvolume will be mounted";
            default = "/persist";
            example = "/persistence";
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.boot.enable) {
    programs = {
      fuse = {
        userAllowOther = lib.mkForce true;
      };
    };
    boot = {
      initrd = {
        postDeviceCommands = lib.mkAfter ''
          mkdir -p /btrfs_tmp
          mount /dev/${config.modules.disk.vg}/${config.modules.disk.lvm_volume} /btrfs_tmp

          if [[ -e /btrfs_tmp/root ]]; then
            mkdir -p /btrfs_tmp/snapshots/roots
            timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
            mv /btrfs_tmp/root "/btrfs_tmp/snapshots/roots/$timestamp"
          fi

          delete_subvolume_recursively() {
            IFS=$'\n'
            for subvolume in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
              delete_subvolume_recursively "/btrfs_tmp/snapshots/roots/$subvolume"
            done
            btrfs subvolume delete "$1"
          }

          for subvolume in $(find /btrfs_tmp/snapshots/roots -maxdepth 1 -mtime +7); do
            delete_subvolume_recursively "$subvolume"
          done

          btrfs subvolume create /btrfs_tmp/root
          umount /btrfs_tmp
        '';
      };
    };
    environment = {
      persistence = {
        ${persistPath} = {
          enable = true;
          hideMounts = true;
          directories = [
            "/etc/nixos"
            "/var/lib/nixos"
            "/var/lib/systemd/coredump"
          ];
          files = [
            "/etc/machine-id"
            {
              file = "/var/keys/secret_file";
              parentDirectory = {mode = "u=rwx,g=,o=";};
            }
          ];
        };
      };
    };
    security = {
      sudo = {
        extraConfig = ''
          # rollback results in sudo lectures after each reboot
          Defaults lecture = never
        '';
      };
    };
    systemd = {
      tmpfiles = {
        rules = [
          (lib.mkIf cfg.home-manager.enable "d ${persistPath}/home/ 0777 root root -")
          (lib.mkIf cfg.home-manager.enable "d ${persistPath}/home/${user} 0770 ${user} ${user}-")
        ];
      };
    };
  };
}
