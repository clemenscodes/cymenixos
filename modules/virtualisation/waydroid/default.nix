{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.virtualisation;
  inherit (config.modules.boot.impermanence) persistPath;
  inherit (config.modules.users) user;

  densityScript = pkgs.writeShellScript "waydroid-set-density" ''
    prop=/var/lib/waydroid/waydroid_base.prop
    [ -f "$prop" ] || exit 0
    ${pkgs.gnused}/bin/sed -i '/^ro\.sf\.lcd_density=/d' "$prop"
    echo 'ro.sf.lcd_density=${toString cfg.waydroid.density}' >> "$prop"
  '';
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
    systemd.services.waydroid-container = lib.mkIf (cfg.waydroid.density != null) {
      serviceConfig.ExecStartPre = "${densityScript}";
    };

    virtualisation = {
      waydroid = {
        inherit (cfg.waydroid) enable;
      };
    };
  };
}
