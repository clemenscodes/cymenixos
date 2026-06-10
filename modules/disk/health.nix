{lib, ...}: {
  config,
  pkgs,
  ...
}: let
  cfg = config.modules.disk.health;
  zpool = config.modules.disk.zpool;

  # Portable notify core. Runs as root (systemd/smartd context) and pushes a
  # desktop notification into every active graphical session, resolving each
  # user's D-Bus address since root has none. Always logs to the journal too,
  # so a fault that fires while no session is live still leaves a record.
  #
  # Init-agnostic: only depends on the XDG /run/user/$uid convention, not on
  # systemd/logind. Reuse verbatim on igris under any init.
  notify = pkgs.writeShellApplication {
    name = "disk-health-notify";
    runtimeInputs = [pkgs.libnotify pkgs.util-linux pkgs.coreutils];
    text = ''
      title=''${1:-Disk health alert}
      body=''${2:-}
      urgency=''${3:-critical}

      logger -t disk-health -p daemon.warning "[$urgency] $title: $body" || true

      shopt -s nullglob
      for rundir in /run/user/*; do
        [ -S "$rundir/bus" ] || continue
        uid=$(basename "$rundir")
        user=$(id -nu "$uid" 2>/dev/null) || continue
        runuser -u "$user" -- env \
          DBUS_SESSION_BUS_ADDRESS="unix:path=$rundir/bus" \
          XDG_RUNTIME_DIR="$rundir" \
          notify-send -u "$urgency" -a disk-health -i drive-harddisk \
          "$title" "$body" 2>/dev/null || true
      done
    '';
  };

  # Polls the pool rather than relying on ZED (whose NixOS service is gated
  # behind boot.zfs.enabled, the same gate this stack avoids). A 15-minute poll
  # is ample for "go replace a disk" urgency and is trivially portable.
  poolCheck = pkgs.writeShellApplication {
    name = "zpool-health-check";
    runtimeInputs = [zpool.zfsPackage notify pkgs.gnugrep pkgs.coreutils];
    text = ''
      pool=''${1:?usage: zpool-health-check POOL}

      if ! zpool list -H -o name "$pool" >/dev/null 2>&1; then
        disk-health-notify "ZFS pool $pool is MISSING" "The pool is not imported." critical
        exit 0
      fi

      # zpool status -x prints "...is healthy" when the pool is ONLINE with no
      # known data errors; otherwise it prints the full degraded/faulted status.
      xout=$(zpool status -x "$pool" 2>&1 || true)
      case "$xout" in
        *"is healthy"*) ;;
        *)
          disk-health-notify "ZFS pool $pool needs attention" "$(zpool status "$pool")" critical
          exit 0
          ;;
      esac

      # Catch permanent data errors that -x may still summarise as healthy.
      errline=$(zpool status "$pool" | grep -E '^[[:space:]]*errors:' || true)
      case "$errline" in
        ""|*"No known data errors"*) ;;
        *)
          disk-health-notify "ZFS pool $pool data errors" "$(zpool status "$pool")" critical
          ;;
      esac
    '';
  };

  # smartd calls this via -M exec; it hands us the failure via SMARTD_* env.
  smartHandler = pkgs.writeShellApplication {
    name = "smartd-health-notify";
    runtimeInputs = [notify];
    text = ''
      disk-health-notify \
        "SMART warning: ''${SMARTD_DEVICESTRING:-disk} (''${SMARTD_FAILTYPE:-failure})" \
        "''${SMARTD_MESSAGE:-A SMART self-check reported a problem.}" \
        critical
    '';
  };
in {
  options = {
    modules = {
      disk = {
        health = {
          enable =
            lib.mkEnableOption "Disk health monitoring (SMART + ZFS pool watch) with desktop alerts";
          smart = {
            enable =
              lib.mkEnableOption "smartd SMART monitoring of physical disks";
          };
          poolWatch = {
            enable =
              lib.mkEnableOption "Periodic ZFS pool health poll with desktop alerts";
            interval = lib.mkOption {
              type = lib.types.str;
              default = "*:0/15";
              description = "Systemd calendar expression for how often to poll pool health";
            };
          };
        };
      };
    };
  };

  config = lib.mkIf (config.modules.enable && cfg.enable) (lib.mkMerge [
    (lib.mkIf cfg.smart.enable {
      services.smartd = {
        enable = true;
        autodetect = true;
        # -m <nomailer> + our own -M exec: no email, just our notifier.
        # Short test daily 02:00, long test Saturday 03:00, temp warn at 45C.
        defaults.monitored = "-a -o on -S on -s (S/../.././02|L/../../6/03) -W 4,50,60 -M exec ${smartHandler}/bin/smartd-health-notify";
      };
    })
    (lib.mkIf (cfg.poolWatch.enable && zpool.enable) {
      systemd = {
        services."zpool-health-${zpool.name}" = {
          description = "Poll ZFS pool \"${zpool.name}\" health";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${poolCheck}/bin/zpool-health-check ${zpool.name}";
          };
        };
        timers."zpool-health-${zpool.name}" = {
          description = "Periodic ZFS pool \"${zpool.name}\" health poll";
          wantedBy = ["timers.target"];
          timerConfig = {
            OnCalendar = cfg.poolWatch.interval;
            Persistent = true;
          };
        };
      };
    })
  ]);
}
