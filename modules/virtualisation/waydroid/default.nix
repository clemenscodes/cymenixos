{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.virtualisation;
in {
  options = {
    modules = {
      virtualisation = {
        waydroid = {
          enable = lib.mkEnableOption "Enable waydroid" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.waydroid.enable) {
    environment = {
      persistence = {
        ${config.modules.boot.impermanence.persistPath} = {
          directories = ["/etc/waydroid-extra" "/var/lib/waydroid"];
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
            echo "waydroid-session-stop"
            sudo mount --bind ~/Documents ~/.local/share/waydroid/data/media/0/Documents
            sudo mount --bind ~/Downloads ~/.local/share/waydroid/data/media/0/Download
            sudo mount --bind ~/Music ~/.local/share/waydroid/data/media/0/Music
            sudo mount --bind ~/Pictures ~/.local/share/waydroid/data/media/0/Pictures
            sudo mount --bind ~/Videos ~/.local/share/waydroid/data/media/0/Movies
          '';
        })
      ];
    };
    virtualisation = {
      waydroid = {
        inherit (cfg.waydroid) enable;
      };
    };
  };
}
