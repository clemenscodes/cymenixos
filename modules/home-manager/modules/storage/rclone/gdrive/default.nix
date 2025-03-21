{
  pkgs,
  lib,
  ...
}: {
  osConfig,
  config,
  ...
}: let
  cfg = config.modules.storage;
  mountGoogleDrive = pkgs.writeShellScriptBin "mount-gdrive" ''
    RCLONE_HOME="$XDG_CONFIG_HOME/rclone"
    STORAGE="${cfg.rclone.gdrive.storage}"

    mkdir -p $STORAGE $RCLONE_HOME

    echo "[${cfg.rclone.gdrive.mount}]" > $RCLONE_HOME/${cfg.rclone.gdrive.config}
    echo "type = drive" >> $RCLONE_HOME/${cfg.rclone.gdrive.config}
    echo "scope = drive" >> $RCLONE_HOME/${cfg.rclone.gdrive.config}
    echo "team_drive = " >> $RCLONE_HOME/${cfg.rclone.gdrive.config}

    echo >> $RCLONE_HOME/${cfg.rclone.gdrive.config}

    echo "[${cfg.rclone.gdrive.mount}_crypt]" >> $RCLONE_HOME/${cfg.rclone.gdrive.config}
    echo "type = crypt" >> $RCLONE_HOME/${cfg.rclone.gdrive.config}
    echo "remote = ${cfg.rclone.gdrive.mount}:" >> $RCLONE_HOME/${cfg.rclone.gdrive.config}
    echo "filename_encryption = standard" >> $RCLONE_HOME/${cfg.rclone.gdrive.config}
    echo "directory_name_encryption = true" >> $RCLONE_HOME/${cfg.rclone.gdrive.config}

    ${pkgs.rclone}/bin/rclone \
      --config $RCLONE_HOME/${cfg.rclone.gdrive.config} \
      --drive-client-id $(${pkgs.bat}/bin/bat ${cfg.rclone.gdrive.clientId} --style=plain) \
      --drive-client-secret $(${pkgs.bat}/bin/bat ${cfg.rclone.gdrive.clientSecret} --style=plain) \
      --drive-token $(${pkgs.bat}/bin/bat ${cfg.rclone.gdrive.token} --style=plain) \
      --crypt-password $(${pkgs.bat}/bin/bat ${cfg.rclone.gdrive.encryption_password} --style=plain) \
      --crypt-password2 $(${pkgs.bat}/bin/bat ${cfg.rclone.gdrive.encryption_salt} --style=plain) \
      --cache-dir "$XDG_RUNTIME_DIR" \
      --vfs-cache-mode full \
      --vfs-cache-max-size 262144 \
      --poll-interval 10m \
      mount ${cfg.rclone.gdrive.crypt}: $STORAGE
  '';
  unmountGoogleDrive = pkgs.writeShellScriptBin "unmount-gdrive" ''
    MOUNT="${cfg.rclone.gdrive.storage}"

    ${pkgs.psmisc}/bin/fuser -Mk -SIGTERM -m "$MOUNT"

    while true;
    do
      if ${pkgs.psmisc}/bin/fuser -m "$MOUNT";
      then
        echo "Mount $MOUNT is busy, waiting..."
        ${pkgs.coreutils}/bin/sleep 1
      else
        echo "Unmounting $MOUNT"
        if fusermount -u "$MOUNT"; then
            echo "Successfully unmounted $MOUNT"
            exit 0
        else
            echo "Failed to unmount $MOUNT" >&2
            exit 1
        fi
      fi
    done
  '';
  syncGoogleDrive = pkgs.writeShellScriptBin "sync-gdrive" ''
    RCLONE_HOME="$XDG_CONFIG_HOME/rclone"
    SYNC_PATH="${cfg.rclone.gdrive.sync}"

    ${pkgs.coreutils}/bin/mkdir -p $RCLONE_HOME $SYNC_PATH

    while true; do
      echo "Starting sync to $SYNC_PATH"
      ${pkgs.rclone}/bin/rclone \
        --config $RCLONE_HOME/${cfg.rclone.gdrive.config} \
        --drive-client-id $(${pkgs.bat}/bin/bat ${cfg.rclone.gdrive.clientId} --style=plain) \
        --drive-client-secret $(${pkgs.bat}/bin/bat ${cfg.rclone.gdrive.clientSecret} --style=plain) \
        --drive-token $(${pkgs.bat}/bin/bat ${cfg.rclone.gdrive.token} --style=plain) \
        --crypt-password $(${pkgs.bat}/bin/bat ${cfg.rclone.gdrive.encryption_password} --style=plain) \
        --crypt-password2 $(${pkgs.bat}/bin/bat ${cfg.rclone.gdrive.encryption_salt} --style=plain) \
        sync ${cfg.rclone.gdrive.crypt}: $SYNC_PATH \
        -Pv \
        --check-first \
        --cutoff-mode soft \
        --transfers=4 \
        --bwlimit=8.5M \
        --progress
      echo "Sync completed. Waiting for 10 minutes..."
      ${pkgs.coreutils}/bin/sleep 600
    done
  '';
in {
  options = {
    modules = {
      storage = {
        rclone = {
          gdrive = {
            enable = lib.mkEnableOption "Enable Google Drive" // {default = false;};
            mount = lib.mkOption {
              type = lib.types.str;
              default = "gdrive";
            };
            crypt = lib.mkOption {
              type = lib.types.str;
              default = "${cfg.rclone.gdrive.mount}_crypt";
            };
            config = lib.mkOption {
              type = lib.types.str;
              default = "${cfg.rclone.gdrive.mount}.conf";
            };
            storage = lib.mkOption {
              type = lib.types.str;
              default = "$HOME/.local/share/storage/${cfg.rclone.gdrive.mount}";
            };
            sync = lib.mkOption {
              type = lib.types.str;
              default = "$HOME/.local/share/sync/${cfg.rclone.gdrive.mount}";
            };
            clientId = lib.mkOption {
              type = lib.types.path;
              default = null;
            };
            clientSecret = lib.mkOption {
              type = lib.types.path;
              default = null;
            };
            token = lib.mkOption {
              type = lib.types.path;
              default = null;
            };
            encryption_password = lib.mkOption {
              type = lib.types.path;
              default = null;
            };
            encryption_salt = lib.mkOption {
              type = lib.types.path;
              default = null;
            };
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.rclone.enable && cfg.rclone.gdrive.enable) {
    home = {
      packages = [
        pkgs.fuse
        mountGoogleDrive
        unmountGoogleDrive
        syncGoogleDrive
      ];
      sessionVariables = {
        GDRIVE_STORAGE = cfg.rclone.gdrive.storage;
        GDRIVE_SYNC = cfg.rclone.gdrive.sync;
      };
      persistence = {
        "${osConfig.modules.boot.impermanence.persistPath}${config.home.homeDirectory}" = {
          directories = [".local/share/sync/${cfg.rclone.gdrive.mount}"];
        };
      };
    };
    programs = {
      zsh = {
        shellAliases = lib.mkIf config.modules.shell.zsh.enable {
          gdrives = "$EXPLORER $GDRIVE_STORAGE";
          gsync = "$EXPLORER $GDRIVE_SYNC";
        };
      };
    };
    systemd = {
      user = {
        services = {
          "rclone-${cfg.rclone.gdrive.mount}" = {
            Unit = {
              Description = cfg.rclone.gdrive.mount;
              After = ["network-online.target" "sops-nix.service"];
            };
            Install = {
              WantedBy = ["default.target"];
            };
            Service = {
              Type = "simple";
              Restart = "always";
              RestartSec = "5s";
              ExecStart = lib.getExe mountGoogleDrive;
              ExecStop = lib.getExe unmountGoogleDrive;
            };
          };
          "rclone-${cfg.rclone.gdrive.mount}-sync" = {
            Unit = {
              Description = "${cfg.rclone.gdrive.mount} sync";
              After = ["rclone-${cfg.rclone.gdrive.mount}.service"];
            };
            Install = {
              WantedBy = ["default.target"];
            };
            Service = {
              Type = "simple";
              ExecStart = lib.getExe syncGoogleDrive;
            };
          };
        };
      };
    };
  };
}
