{
  pkgs,
  lib,
  ...
}: {
  config,
  osConfig,
  ...
}: let
  hyprlockExe = lib.getExe hyprlock;
  cfg = config.modules.display.lockscreen;
  suspendScript = pkgs.writeShellScript "suspend-script" ''
    ${lib.getExe pkgs.playerctl} -a status | ${lib.getExe pkgs.ripgrep} Playing -q
    if [ $? == 1 ]; then
      ${pkgs.systemd}/bin/systemctl suspend
    fi
  '';
  brightness = lib.getExe pkgs.brightnessctl;
  timeout = 3000;
  inherit (pkgs) hyprlock hypridle;
in {
  options = {
    modules = {
      display = {
        lockscreen = {
          hyprlock = {
            enable = lib.mkEnableOption "Enable hyprlock" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.hyprlock.enable) {
    home = {
      packages = [
        hyprlock
        hypridle
      ];
    };
    programs = {
      hyprlock = {
        inherit (cfg.hyprlock) enable;
        settings = {
          general = {
            grace = 0;
            disable_loading_bar = true;
            hide_cursor = true;
          };
          background = [
            {
              monitor = "";
              path = "$XDG_WALLPAPER_DIR/random";
              blur_passes = "0";
              color = "$base";
            }
          ];
          label = [];
        };
      };
    };
    services = {
      hypridle = {
        inherit (cfg.hyprlock) enable;
        settings = {
          general = {
            lock_cmd = "pidof ${hyprlockExe} || ${hyprlockExe}";
            before_sleep_cmd = "${pkgs.systemd}/bin/loginctl lock-session";
            ignore_dbus_inhibit = false;
            ignore_systemd_inhibit = false;
          };
          listener = [
            {
              timeout = (timeout / 2) - 30;
              on-timeout = ''${pkgs.libnotify}/bin/notify-send "Idle! dimming colors soon..."'';
            }
            {
              timeout = (timeout / 2) - 10;
              on-timeout = "${brightness} set 10%-";
              on-resume = "${brightness} set 100%";
            }
            {
              timeout = timeout - 30;
              on-timeout = ''${pkgs.libnotify}/bin/notify-send "Locking session soon..."'';
            }
            {
              inherit timeout;
              on-timeout = "${pkgs.systemd}/bin/loginctl lock-session";
            }
            {
              timeout = timeout + 30;
              on-timeout = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off";
              on-resume = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
            }
            {
              timeout = timeout * 2;
              on-timeout = suspendScript.outPath;
            }
          ];
        };
      };
    };
  };
}
