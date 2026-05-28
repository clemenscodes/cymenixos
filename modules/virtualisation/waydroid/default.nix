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
    runtimeInputs = [pkgs.cage pkgs.waydroid];
    text = ''
      exec cage -- waydroid show-full-ui "$@"
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
