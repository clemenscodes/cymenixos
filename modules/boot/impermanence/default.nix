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
  config = lib.mkIf (cfg.enable && cfg.boot.enable && !cfg.users.isIso) {
    home-manager = lib.mkIf cfg.home-manager.enable {
      users = {
        ${user} = {
          imports = [inputs.impermanence.homeManagerModules.impermanence];
          home = {
            persistence = {
              allowOther = true;
            };
          };
        };
      };
    };
    programs = {
      fuse = {
        userAllowOther = lib.mkForce true;
      };
    };
    boot = {
      initrd = {
        postDeviceCommands = lib.mkAfter ''
          mkdir -p /btrfs_tmp
          mount /dev/root_vg/root /btrfs_tmp

          if [[ -e /btrfs_tmp/root ]]; then
            mkdir -p /btrfs_tmp/old_roots
            timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
            mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
          fi

          delete_subvolume_recursively() {
            IFS=$'\n'
            for subvolume in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
              delete_subvolume_recursively "/btrfs_tmp/old_roots/$subvolume"
            done
            btrfs subvolume delete "$1"
          }

          for subvolume in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
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
            "/var/log"
            "/var/lib/nixos"
            "/var/lib/systemd/coredump"
          ];
          files = [
            "/etc/machine-id"
            "/etc/adjtime"
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
          "d ${persistPath}/home/ 0777 root root -"
          (lib.mkIf cfg.home-manager.enable "d ${persistPath}/home/${user} 0770 ${user} ${user}-")
        ];
      };
    };
  };
}
