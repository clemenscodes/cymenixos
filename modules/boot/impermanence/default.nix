{
  inputs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
  homeCfg = config.home-manager.users.${user}.modules;
  inherit (cfg.users) user;
  # linkFileToPersist = file: "L ${file} - - - - ${persistPath}/${file}";
  inherit (cfg.boot.impermanence) persistPath;
in {
  imports = [inputs.impermanence.nixosModules.impermanence];
  options = {
    modules = {
      boot = {
        impermanence = {
          persistPath = lib.mkOption {
            type = lib.types.str;
            default = "/persist";
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.boot.enable && !cfg.users.isIso) {
    programs = {
      fuse = {
        userAllowOther = true;
      };
    };
    boot = {
      initrd = {
        postDeviceCommands = lib.mkAfter ''
          mkdir -p /btrfs_tmp
          mount /dev/root_vg/root /btrfs_tmp

          delete_subvolume_recursively() {
            IFS=$'\n'
            for subvolume in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
              delete_subvolume_recursively "/btrfs_tmp/$subvolume"
            done
            btrfs subvolume delete "$1"
          }

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
            "/etc/adjtime"
            "/var/log"
            "/var/lib/nixos"
            "/var/lib/systemd/coredump"
            (lib.mkIf (cfg.networking.enable) "/etc/NetworkManager/system-connections")
            (lib.mkIf (cfg.networking.enable && cfg.networking.bluetooth.enable) "/var/lib/bluetooth")
            (lib.mkIf (cfg.virtualisation.enable && cfg.virtualisation.docker.enable) "/var/lib/docker")
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
    # environment = {
    #   etc = {
    #     nixos = {
    #       source = "${persistPath}/etc/nixos";
    #     };
    #     NIXOS = {
    #       source = "${persistPath}/etc/NIXOS";
    #     };
    #     machine-id = {
    #       source = "${persistPath}/etc/machine-id";
    #     };
    #     adjtime = {
    #       source = "${persistPath}/etc/adjtime";
    #     };
    #     "NetworkManager/system-connections" = {
    #       source = "${persistPath}/etc/NetworkManager/system-connections";
    #     };
    #   };
    # };
    systemd = {
      tmpfiles = {
        rules = [
          "d ${persistPath}/home/ 0777 root root -"
          (lib.mkIf cfg.home-manager.enable "d ${persistPath}/home/${user} 0770 ${user} ${user}-")
          # (lib.mkIf (cfg.networking.enable) (linkFileToPersist "/var/lib/NetworkManager/secret_key"))
          # (lib.mkIf (cfg.networking.enable) (linkFileToPersist "/var/lib/NetworkManager/seen-bssids"))
          # (lib.mkIf (cfg.networking.enable) (linkFileToPersist "/var/lib/NetworkManager/timestamps"))
          # (lib.mkIf (cfg.networking.enable && cfg.networking.bluetooth.enable) (linkFileToPersist "/var/lib/bluetooth"))
          # (lib.mkIf (cfg.virtualisation.enable && cfg.virtualisation.docker.enable) (linkFileToPersist "/var/lib/docker"))
        ];
      };
    };
    home-manager = lib.mkIf cfg.home-manager.enable {
      users = {
        ${user} = {
          imports = [inputs.impermanence.nixosModules.home-manager.impermanence];
          home = {
            persistence = {
              "${persistPath}/home" = {
                allowOther = true;
                directories = [
                  (lib.mkIf (homeCfg.xdg.enable) "Downloads")
                  (lib.mkIf (homeCfg.xdg.enable) "Music")
                  (lib.mkIf (homeCfg.xdg.enable) "Pictures")
                  (lib.mkIf (homeCfg.xdg.enable) "Documents")
                  (lib.mkIf (homeCfg.xdg.enable) "Videos")
                  ".local/src"
                  ".local/bin"
                  ".local/share/keyrings"
                  (lib.mkIf (homeCfg.development.direnv.enable) ".local/share/direnv")
                  (lib.mkIf (cfg.security.enable && cfg.security.ssh.enable && homeCfg.security.enable && homeCfg.security.ssh.enable) ".ssh")
                  (lib.mkIf (cfg.gaming.enable && cfg.gaming.steam.enable) {
                    directory = ".local/share/Steam";
                    method = "symlink";
                  })
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
