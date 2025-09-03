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
    set -euo pipefail

    RCLONE_HOME="$XDG_CONFIG_HOME/rclone"
    STORAGE="${cfg.rclone.gdrive.storage}"
    CONFIG_FILE="$RCLONE_HOME/${cfg.rclone.gdrive.config}"

    ${pkgs.coreutils}/bin/mkdir -p "$STORAGE" "$RCLONE_HOME"

    CLIENT_ID="$(${pkgs.coreutils}/bin/cat ${cfg.rclone.gdrive.clientId})"
    CLIENT_SECRET="$(${pkgs.coreutils}/bin/cat ${cfg.rclone.gdrive.clientSecret})"
    TOKEN="$(${pkgs.coreutils}/bin/cat ${cfg.rclone.gdrive.token})"
    RAW_PASS="$(${pkgs.coreutils}/bin/cat ${cfg.rclone.gdrive.encryption_password})"
    RAW_SALT="$(${pkgs.coreutils}/bin/cat ${cfg.rclone.gdrive.encryption_salt})"
    OBSCURED_PASS="$(${pkgs.rclone}/bin/rclone obscure "$RAW_PASS")"
    OBSCURED_SALT="$(${pkgs.rclone}/bin/rclone obscure "$RAW_SALT")"

    {
      echo "[${cfg.rclone.gdrive.mount}]"
      echo "type = drive"
      echo "scope = drive"
      echo "team_drive ="
      echo "client_id = $CLIENT_ID"
      echo "client_secret = $CLIENT_SECRET"
      echo "token = $TOKEN"
      echo
      echo "[${cfg.rclone.gdrive.mount}_crypt]"
      echo "type = crypt"
      echo "remote = ${cfg.rclone.gdrive.mount}:"
      echo "filename_encryption = standard"
      echo "directory_name_encryption = true"
      echo "password = $OBSCURED_PASS"
      echo "password2 = $OBSCURED_SALT"
      echo
      echo "[${cfg.rclone.gdrive.mount}_mount]"
      echo "type = alias"
      echo "remote = ${cfg.rclone.gdrive.mount}_crypt:"
      echo "vfs_cache_mode = full"
      echo "vfs_cache_max_size = 262144"
      echo "poll_interval = 10m"
      echo "cache_dir = $XDG_RUNTIME_DIR"
    } > "$CONFIG_FILE"

    ${pkgs.rclone}/bin/rclone \
      --config "$CONFIG_FILE" \
      mount ${cfg.rclone.gdrive.mount}_mount: "$STORAGE"
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
        pkgs.fuse3
        mountGoogleDrive
        unmountGoogleDrive
        syncGoogleDrive
      ];
      sessionVariables = {
        GDRIVE_STORAGE = cfg.rclone.gdrive.storage;
        GDRIVE_SYNC = cfg.rclone.gdrive.sync;
      };
      persistence = lib.mkIf (osConfig.modules.boot.enable) {
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
