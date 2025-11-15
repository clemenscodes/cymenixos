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
