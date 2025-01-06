{
  inputs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
  homeCfg = config.home-manager.users.${user}.modules;
  inherit (cfg.users) user;
in {
  imports = [inputs.impermanence.nixosModules.impermanence];
  config = lib.mkIf (cfg.enable && cfg.boot.enable && !cfg.users.isIso) {
    programs = {
      fuse = {
        userAllowOther = true;
      };
    };
    boot = {
      initrd = {
        postDeviceCommands = lib.mkAfter ''
          mkdir /btrfs_tmp
          mount /dev/root_vg/root /btrfs_tmp
          if [[ -e /btrfs_tmp/root ]]; then
              mkdir -p /btrfs_tmp/old_roots
              timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
              mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
          fi

          delete_subvolume_recursively() {
              IFS=$'\n'
              for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
                  delete_subvolume_recursively "/btrfs_tmp/$i"
              done
              btrfs subvolume delete "$1"
          }

          for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
              delete_subvolume_recursively "$i"
          done

          btrfs subvolume create /btrfs_tmp/root
          umount /btrfs_tmp
        '';
      };
    };
    environment = {
      persistence = {
        "/persist" = {
          enable = true;
          hideMounts = true;
          directories = [
            "/var/log"
            "/var/lib/bluetooth"
            "/var/lib/nixos"
            "/var/lib/systemd/coredump"
            "/etc/NetworkManager/system-connections"
            {
              directory = "/var/lib/colord";
              user = "colord";
              group = "colord";
              mode = "u=rwx,g=rx,o=";
            }
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
    home-manager = lib.mkIf cfg.home-manager.enable {
      users = {
        ${user} = {
          imports = [inputs.impermanence.nixosModules.home-manager.impermanence];
          home = {
            persistence = {
              "/persist/home" = {
                allowOther = true;
                directories = [
                  "Downloads"
                  "Music"
                  "Pictures"
                  "Documents"
                  "Videos"
                  ".ssh"
                  ".cache/BraveSoftware"
                  ".config/gnupg"
                  ".config/BraveBrowser"
                  ".config/Bitwarden"
                  ".config/Mullvad VPN"
                  ".config/obs-studio"
                  ".config/qBittorrent"
                  ".local/share/keyrings"
                  ".local/share/direnv"
                  ".local/share/mail"
                  ".local/src"
                  ".local/bin"
                  {
                    directory = ".local/share/Steam";
                    method = "symlink";
                  }
                  (lib.mkIf (homeCfg.storage.enable && homeCfg.storage.rclone.enable && homeCfg.storage.rclone.gdrive.enable) homeCfg.storage.rclone.gdrive.sync)
                ];
              };
            };
          };
        };
      };
    };
  };
}
