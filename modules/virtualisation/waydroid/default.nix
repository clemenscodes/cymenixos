{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.virtualisation;
  inherit (config.modules.boot.impermanence) persistPath;
  inherit (config.modules.users) user;

  w = cfg.waydroid;

  propScript = pkgs.writeShellScript "waydroid-base-props" ''
    prop=/var/lib/waydroid/waydroid_base.prop
    [ -f "$prop" ] || exit 0
    ${lib.optionalString (w.density != null) ''
      ${pkgs.gnused}/bin/sed -i '/^ro\.sf\.lcd_density=/d' "$prop"
      echo 'ro.sf.lcd_density=${toString w.density}' >> "$prop"
    ''}
    ${lib.optionalString (w.width != null) ''
      ${pkgs.gnused}/bin/sed -i '/^persist\.waydroid\.width=/d' "$prop"
      echo 'persist.waydroid.width=${toString w.width}' >> "$prop"
    ''}
    ${lib.optionalString (w.height != null) ''
      ${pkgs.gnused}/bin/sed -i '/^persist\.waydroid\.height=/d' "$prop"
      echo 'persist.waydroid.height=${toString w.height}' >> "$prop"
    ''}
  '';

  hasProps = w.density != null || w.width != null || w.height != null;

  waydroid-ui = pkgs.writeShellApplication {
    name = "waydroid-ui";
    runtimeInputs = [pkgs.cage pkgs.waydroid pkgs.coreutils pkgs.gnugrep pkgs.procps pkgs.util-linux pkgs.hyprland];
    text = ''
      # Single-instance guard. A second cage trying to attach to a
      # waydroid session that's already attached to another cage will
      # spin forever on 'Failed to get service waydroidplatform', stick
      # the session, and the only fix is killing both cages plus the
      # container — so refuse the second launch up front.
      # Single-instance guard. A second cage attaching to a session
      # that's already owned by another cage spins on 'Failed to get
      # service waydroidplatform'. If the cage window still exists
      # (e.g. on a non-active workspace) just focus it instead of
      # refusing.
      lockdir="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/waydroid-ui"
      mkdir -p "$lockdir"
      lockfile="$lockdir/lock"
      exec 9>"$lockfile"
      if ! flock -n 9; then
        echo "waydroid-ui: already running; focusing existing cage window"
        hyprctl dispatch 'hl.dsp.focus({ window = "class:wlroots" })' >/dev/null 2>&1 || true
        exit 0
      fi

      # Find the amdgpu render node — Android renders via mesa minigbm
      # on the AMD iGPU. Its DPM 'auto' governor doesn't ramp the iGPU
      # up under sustained 4K Android workloads even at 100% busy, so
      # pin it to 'high' while a session is alive and restore on exit.
      amd_card=""
      for c in /sys/class/drm/card[0-9]*; do
        [ -d "$c/device" ] || continue
        if grep -q amdgpu "$c/device/uevent" 2>/dev/null; then
          amd_card="$c"
          break
        fi
      done

      perf_file=""
      prev_perf=""
      if [ -n "$amd_card" ] && [ -f "$amd_card/device/power_dpm_force_performance_level" ]; then
        perf_file="$amd_card/device/power_dpm_force_performance_level"
        prev_perf="$(cat "$perf_file")"
        if sudo -n sh -c "echo high > $perf_file" 2>/dev/null; then
          echo "waydroid-ui: pinned $amd_card to high perf (was $prev_perf)"
          # shellcheck disable=SC2064
          trap "sudo -n sh -c 'echo $prev_perf > $perf_file' 2>/dev/null || true; waydroid session stop >/dev/null 2>&1 || true" EXIT
        else
          echo "waydroid-ui: could not bump iGPU clock (sudo prompt or denied); continuing anyway"
          trap "waydroid session stop >/dev/null 2>&1 || true" EXIT
        fi
      else
        trap "waydroid session stop >/dev/null 2>&1 || true" EXIT
      fi

      # NB: closing the cage window in Hyprland (Mod+Q etc.) only
      # sends xdg_toplevel.close, which cage 0.3.0 ignores because its
      # wrapped command ('waydroid show-full-ui') is still alive. The
      # clean exit path is the 'Stop Waydroid' desktop entry, which
      # calls 'waydroid session stop' — that exits show-full-ui, which
      # exits cage, which lets this script's EXIT trap restore the
      # iGPU governor.
      cage -- waydroid show-full-ui "$@"
    '';
  };
in {
  options = {
    modules = {
      virtualisation = {
        waydroid = {
          enable = lib.mkEnableOption "Enable waydroid" // {default = false;};
          density = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
            example = 320;
            description = ''
              Android display density (DPI) written to ro.sf.lcd_density
              in waydroid_base.prop before each container start.
              Recommended: 160 (1080p), 240 (1440p), 320 (4K).
              null leaves the value from waydroid init unchanged.
            '';
          };
          width = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
            example = 3840;
            description = ''
              Android display width in pixels (persist.waydroid.width).
              Written to waydroid_base.prop as the initial default; Android
              picks it up on first boot and stores it in persistent_properties.
              Match your fullscreen window width. null = auto-detect.
            '';
          };
          height = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
            example = 2160;
            description = ''
              Android display height in pixels (persist.waydroid.height).
              See width. null = auto-detect.
            '';
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.waydroid.enable) {
    environment = {
      persistence = {
        ${persistPath} = {
          directories = ["/etc/waydroid-extra" "/var/lib/waydroid"];
          users = {
            ${user} = {
              directories = [".local/share/waydroid"];
            };
          };
        };
      };
      systemPackages = [
        pkgs.waydroid-helper
        waydroid-ui
        (pkgs.writeShellApplication {
          name = "waydroid-aid";
          runtimeInputs = [
            pkgs.waydroid
            pkgs.waydroid-helper
            pkgs.wl-clipboard
          ];
          text = ''
            sudo waydroid shell -- sh -c "sqlite3 /data/data/*/*/gservices.db 'select * from main where name = \"android_id\";'" | awk -F '|' '{print $2}' | wl-copy
            echo "Paste clipboard in this website below"
            echo "https://www.google.com/android/uncertified"
            echo "Then run"
            echo "waydroid session stop"
            sudo mount --bind ~/Documents ~/.local/share/waydroid/data/media/0/Documents
            sudo mount --bind ~/Downloads ~/.local/share/waydroid/data/media/0/Download
            sudo mount --bind ~/Music ~/.local/share/waydroid/data/media/0/Music
            sudo mount --bind ~/Pictures ~/.local/share/waydroid/data/media/0/Pictures
            sudo mount --bind ~/Videos ~/.local/share/waydroid/data/media/0/Movies
          '';
        })
      ];
    };

    systemd.services.waydroid-container = lib.mkIf hasProps {
      serviceConfig.ExecStartPre = "${propScript}";
    };

    virtualisation = {
      waydroid = {
        inherit (cfg.waydroid) enable;
      };
    };

    # When the cage wlroots window closes (e.g. Mod+Q in Hyprland),
    # tear the waydroid session down so the next launch starts clean.
    # Without this the session lingers in RUNNING state, the next
    # cage attaches to nothing, and the user sees no window.
    modules.io.hyprhook.rules = lib.mkIf config.modules.io.hyprhook.enable [
      {
        class = "^wlroots$";
        on_close = ["${pkgs.waydroid}/bin/waydroid" "session" "stop"];
      }
    ];

    home-manager.users.${user} = {
      wayland.windowManager.hyprland.extraConfig = ''
        hl.window_rule({ match = { class = "^(wlroots)$" }, fullscreen = true, immediate = true })
      '';
      xdg.desktopEntries = {
        Waydroid = {
          name = "Waydroid";
          type = "Application";
          exec = "${waydroid-ui}/bin/waydroid-ui";
          icon = "waydroid";
          categories = ["Utility"];
          startupNotify = true;
          settings = {
            StartupWMClass = "wlroots";
          };
        };
        Waydroid-Stop = {
          name = "Stop Waydroid";
          comment = "Stop the Waydroid Android session";
          type = "Application";
          exec = "${pkgs.waydroid}/bin/waydroid session stop";
          icon = "waydroid";
          categories = ["Utility"];
        };
      };
    };
  };
}
