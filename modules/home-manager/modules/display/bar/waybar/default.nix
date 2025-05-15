{
  inputs,
  lib,
  ...
}: {
  config,
  osConfig,
  system,
  ...
}: let
  cfg = config.modules.display.bar;
  isLaptop = osConfig.modules.machine.kind == "laptop";
  isNvidia = osConfig.modules.gpu.nvidia.enable;
  isAmd = osConfig.modules.gpu.amd.enable;
  useYubi = osConfig.modules.security.yubikey.enable;
  useEmail = config.modules.organization.email.enable;
  useMusic = config.modules.media.music.enable;
  useHyprland = config.modules.display.compositor.hyprland.enable;
  useSwaync = config.modules.display.notifications.swaync.enable;
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [
      (final: prev: {
        waybar = prev.waybar.overrideAttrs (oldAttrs: {
          src = prev.fetchFromGitHub {
            owner = "Alexays";
            repo = "Waybar";
            rev = "67272cc47f430dcb82f533e29ae26495f7876154";
            hash = "sha256-Q+ZrEkJr1sEu48VfOtkFrfT3B1yo4fJHB2qE9ZTpmuw=";
          };
        });
      })
    ];
  };
in {
  options = {
    modules = {
      display = {
        bar = {
          waybar = {
            enable = lib.mkEnableOption "Enable Waybar" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.waybar.enable) {
    home = {
      packages = [
        pkgs.libappindicator-gtk3
        pkgs.libdbusmenu-gtk3
        (import ./waybar-clock {inherit inputs pkgs lib;})
        (import ./waybar-mail {inherit inputs pkgs lib;})
        (import ./waybar-powermenu {inherit inputs pkgs lib;})
        (import ./waybar-reload {inherit inputs pkgs lib;})
        (import ./waybar-swaync {inherit inputs pkgs lib;})
        (import ./waybar-toggle {inherit inputs pkgs lib;})
        (import ./waybar-watch {inherit inputs pkgs lib;})
      ];
    };
    programs = {
      waybar = {
        inherit (cfg.waybar) enable;
        package = pkgs.waybar;
        systemd = {
          enable = false;
        };
        settings = let
          height = 60;
          max-volume = 150;
        in [
          {
            inherit height;
            layer = "bottom";
            position = "top";
            name = "topBar";
            modules-left = [
              (lib.mkIf useHyprland "hyprland/workspaces")
            ];
            modules-center = [
              (lib.mkIf useMusic "mpd")
            ];
            modules-right = [
              (lib.mkIf useEmail "custom/mail")
              "disk"
              "memory"
              "temperature"
              "cpu"
              (lib.mkIf isNvidia "custom/nvidiagpuinfo")
              (lib.mkIf isLaptop "battery")
              "custom/powermenu"
            ];
            "hyprland/workspaces" = lib.mkIf useHyprland {
              format = "-> {id}";
              on-click = "activate";
              on-scroll-up = "hyprctl dispatch workspace e+1";
              on-scroll-down = "hyprctl dispatch workspace e-1";
            };
            mpd = lib.mkIf useMusic {
              format = "⸨{songPosition}|{queueLength}⸩ {filename} ({elapsedTime:%H:%M:%S}/{totalTime:%H:%M:%S}) 🎵";
              format-disconnected = "Disconnected 🎵";
              format-stopped = "Stopped 🎵";
              unknown-tag = "N/A";
              server = "/run/user/${builtins.toString osConfig.modules.users.uid}/mpd/socket";
              tooltip-format = "MPD (connected)";
              tooltip-format-disconnected = "MPD (disconnected)";
            };
            "custom/yubikey" = {
              exec = "waybar-yubikey";
              return-type = "json";
            };
            "custom/mail" = lib.mkIf useEmail {
              format = "{}";
              interval = 5;
              exec = "waybar-mail";
              on-click = "${pkgs.kitty}/bin/kitty -1 --title=kitty ${pkgs.neomutt}/bin/neomutt";
            };
            disk = {
              interval = 30;
              format = "{percentage_used}% 💾";
              tooltip-format = "{used}/{total} 💾";
              on-click = "${pkgs.kitty}/bin/kitty -1 --title=kitty ${pkgs.ncdu}/bin/ncdu";
              path = "/";
            };
            memory = {
              format = "{percentage}% 🧠";
              format-alt = "󰾅  {used}GB";
              tooltip-format = "{used:0.1f}G/{total:0.1f}GB  ";
              on-click = "${pkgs.kitty}/bin/kitty -1 --title=kitty ${pkgs.btop}/bin/btop";
              interval = 30;
              tooltip = true;
            };
            cpu = {
              interval = 1;
              format = "{icon0}{icon1}{icon2}{icon3}{icon4}{icon5}{icon6}{icon7} {usage}%";
              format-icons = [
                "<span color='#69ff94'>▁</span>" # green
                "<span color='#2aa9ff'>▂</span>" # blue
                "<span color='#f8f8f2'>▃</span>" # white
                "<span color='#f8f8f2'>▄</span>" # white
                "<span color='#ffffa5'>▅</span>" # yellow
                "<span color='#ffffa5'>▆</span>" # yellow
                "<span color='#ff9977'>▇</span>" # orange
                "<span color='#dd532e'>█</span>" # red
              ];
              on-click = "${pkgs.kitty}/bin/kitty -1 --title=kitty ${pkgs.btop}/bin/btop";
            };
            temperature = {
              critical-threshold = 80;
              hwmon-path-abs = "/sys/devices/platform/coretemp.0/hwmon";
              input-filename = "temp1_input";
              interval = 0.1;
              format = "{temperatureC}°C {icon}";
              format-critical = "{temperatureC}°C 🔥";
              on-click = "${pkgs.kitty}/bin/kitty -1 --title=kitty ${pkgs.btop}/bin/btop";
              format-icons = ["🌡️"];
            };
            "custom/nvidiagpuinfo" = lib.mkIf isNvidia {
              format = "{} 🌡️";
              exec = "nvidiagpuinfo";
              return-type = "json";
              on-click = "nvidia-settings";
              interval = 5;
              tooltip = true;
            };
            battery = lib.mkIf isLaptop {
              states = {
                good = 60;
                warning = 30;
                critical = 15;
              };
              format = "{capacity}% {icon}";
              format-charging = "{capacity}% ⚡";
              format-plugged = "{capacity}% 🔌";
              format-alt = "{time} {icon}";
              format-icons = ["💀" "🪫" "🔋"];
            };
            "custom/powermenu" = {
              format = "";
              on-click = "sleep 0.1 && logoutlaunch";
              exec = "waybar-powermenu";
              tooltip = false;
            };
          }
          {
            inherit height;
            name = "bottomBar";
            layer = "bottom";
            position = "bottom";
            modules-left = [
              "image#logo"
              "wlr/taskbar"
            ];
            modules-center = [];
            modules-right = [
              "hyprland/submap"
              "privacy"
              (lib.mkIf useSwaync "custom/notification")
              "idle_inhibitor"
              "tray"
              (lib.mkIf isLaptop "backlight")
              (lib.mkIf useMusic "pulseaudio")
              (lib.mkIf useMusic "pulseaudio#mic")
              "custom/clock"
            ];
            systemd-failed-units = {
              hide-on-ok = false;
              format = "{nr_failed}";
              format-ok = "✓";
              system = true;
              user = true;
            };
            "hyprland/submap" = {
              format = "{}";
              always-on = true;
              tooltip = false;
              default-submap = "NORMAL";
            };
            "image#logo" = {
              path = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              size = height - 12;
              on-click = "sleep 0.3; ${pkgs.rofi-wayland}/bin/rofi -show drun";
            };
            "wlr/taskbar" = {
              format = "{icon}";
              on-click = "activate";
              on-click-middle = "fullscreen";
              on-click-right = "close";
              icon-theme = "Papirus-Dark";
              icon-size = 22;
              markup = true;
              tooltip = false;
              spacing = 0;
              ignore-list = [
                ""
              ];
            };
            "custom/notification" = lib.mkIf useSwaync {
              format = "{icon}";
              format-icons = {
                notification = "<span foreground='red'></span>";
                none = "<span></span>";
                dnd-notification = "<span foreground='red'></span>";
                dnd-none = "<span></span>";
                dnd-inhibited-notification = "<span foreground='red'></span>";
                dnd-inhibited-none = "<span></span>";
                inhibited-notification = "<span foreground='red'></span>";
                inhibited-none = "<span></span>";
              };
              return-type = "json";
              tooltip = false;
              exec-if = "which ${pkgs.swaynotificationcenter}/bin/swaync-client";
              exec = "${pkgs.swaynotificationcenter}/bin/swaync-client -swb";
              on-click = "waybar-swaync";
              escape = true;
            };
            gamemode = {
              format = "{glyph}";
              format-alt = "{glyph} {count}";
              glyph = "";
              hide-not-running = true;
              use-icon = true;
              icon-name = "input-gaming-symbolic";
              icon-spacing = 4;
              icon-size = 20;
              tooltip = true;
              tooltip-format = "Games running: {count}";
            };
            privacy = {
              icon-spacing = 8;
              icon-size = 18;
              transition-duration = 250;
              modules = [
                {
                  type = "screenshare";
                  tooltip = true;
                  tooltip-icon-size = 24;
                }
                {
                  type = "audio-out";
                  tooltip = true;
                  tooltip-icon-size = 24;
                }
                {
                  type = "audio-in";
                  tooltip = true;
                  tooltip-icon-size = 24;
                }
              ];
            };
            idle_inhibitor = {
              format = "{icon}";
              format-icons = {
                activated = "";
                deactivated = "";
              };
            };
            tray = {
              icon-size = "48 ";
              spacing = 10;
              interval = 1;
              show-passive-items = true;
            };
            backlight = lib.mkIf isLaptop {
              format = "{percent}% {icon}";
              format-icons = ["🌑" "🌘" "🌗" "🌖" "🌕"];
              on-scroll-up = "${pkgs.brightnessctl}/bin/brightnessctl set 1%+";
              on-scroll-down = "${pkgs.brightnessctl}/bin/brightnessctl set 1%-";
            };
            pulseaudio = lib.mkIf useMusic {
              inherit max-volume;
              format = "{volume}% {icon}";
              format-icons = {
                default = ["🔈" "🔉" "🔊"];
                headphones = ["🎧"];
                headset = ["🎧"];
              };
              format-muted = "🔇";
              on-click = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
              on-click-right = "${pkgs.pavucontrol}/bin/pavucontrol";
            };
            "pulseaudio#mic" = lib.mkIf useMusic {
              inherit max-volume;
              format = "{format_source}";
              format-source = "{volume}% 🎤";
              format-source-muted = "🚫 🎤";
              scroll-step = 1;
              on-click = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
              on-scroll-down = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 1%-";
              on-scroll-up = "${pkgs.wireplumber}/bin/wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SOURCE@ 1%+";
              on-click-right = "${pkgs.pavucontrol}/bin/pavucontrol";
            };
            "custom/clock" = {
              format = "{}";
              interval = 1;
              exec = "waybar-clock";
              on-click = "${pkgs.kitty}/bin/kitty -1 --title=kitty ${pkgs.calcurse}/bin/calcurse";
            };
          }
        ];
        style = let
          padding = "padding: 12px;";
          borderRadius = "12px";
          defaultBackground = "background-color: #4A3C63;";
          activeBackground = "background-color: #D8C1C4;";
          urgentBackground = "background-color: #eb4d4b;";
          animation = "animation: gradient_f 20s ease-in infinite;";
          hide = "background: transparent;";
          fadeIn = ''
            ${animation}
            transition: all 0.3s cubic-bezier(.55,-0.68,.48,1.682);
          '';
          fadeOut = ''
            ${animation}
            transition: all 0.5s cubic-bezier(.55,-0.68,.48,1.682);
          '';
          defaultColor = "color: white;";
          activeColor = "color: #58505E;";
          defaultMargin = "12px";
        in ''
          * {
            padding: 0px;
            margin: 0px;
            min-height: 0px;
            min-width: 0px;
            font-family: "Iosevka Nerd Font Mono";
            font-size: 16px;
            font-weight: bold;
          }

          button:hover {
            box-shadow: none;
            text-shadow: none;
            border-color: transparent;
            background: transparent;
          }

          window#waybar.topBar,
          window#waybar.bottomBar
          {
            ${hide}
            color: white;
          }

          tooltip {
            border-radius: ${borderRadius};
            border-width: 0px;
            padding: 12px;
            ${defaultBackground}
            ${defaultColor}
          }

          #image {
            margin: 0px 6px 12px ${defaultMargin};
          }

          #workspaces {
            margin: ${defaultMargin} 0px 0px ${defaultMargin};
            border-radius: 12px;
            ${defaultBackground}
            ${defaultColor}
          }

          #workspaces button {
            ${padding}
            ${fadeIn}
            border-radius: 12px;
          }

          #workspaces button:hover {
            ${activeBackground}
            ${activeColor}
            ${fadeOut}
          }

          #workspaces button.active {
            ${activeBackground}
            ${activeColor}
            ${fadeIn}
          }

          #workspaces button.urgent {
            ${urgentBackground}
          }

          #taskbar {
            ${defaultBackground}
            margin: 0px 6px 12px 6px;
            border-radius: 20px;
          }

          #taskbar button {
            ${defaultBackground}
            ${fadeIn}
            padding: 12px;
            border-radius: 20px;
          }

          #taskbar button.active {
            ${fadeOut}
            ${activeColor}
            ${activeBackground}
          }

          #taskbar button:hover {
            ${fadeOut}
            ${activeColor}
            ${activeBackground}
          }

          #taskbar.empty {
            ${hide}
            padding: 0px;
          }

          #battery,
          #cpu,
          #memory,
          #disk,
          #temperature,
          #backlight,
          #pulseaudio,
          #pulseaudio.mic,
          #idle_inhibitor,
          #tray,
          #systemd-failed-units,
          #submap,
          #privacy,
          #gamemode,
          #custom-clock,
          #custom-notification,
          #custom-powermenu,
          #custom-mail,
          #custom-idle,
          #custom-nvidiagpuinfo,
          #mpd {
            ${padding}
            ${defaultColor}
            ${defaultBackground}
            border-radius: 4px;
          }

          #mpd,
          #custom-mail,
          #disk,
          #memory,
          #cpu,
          #temperature,
          #custom-nvidiagpuinfo,
          #battery,
          #custom-powermenu {
            margin: ${defaultMargin} 4px 0px 4px;
          }

          #systemd-failed-units,
          #submap,
          #tray,
          #custom-idle,
          #privacy,
          #gamemode,
          #custom-notification,
          #idle_inhibitor,
          #backlight,
          #pulseaudio,
          #pulseaudio.mic,
          #custom-clock {
            margin: 0px 4px ${defaultMargin} 4px;
          }

          #custom-notification,
          #custom-powermenu,
          #idle_inhibitor {
            padding: 0px 12px;
            font-size: 28px;
          }

          #custom-clock {
            margin-right: ${defaultMargin};
          }

          #custom-powermenu {
            background-color: #f53c3c;
            color: white;
            margin-right: ${defaultMargin};
          }

          @keyframes blink {
            to {
              background-color: #f53c3c;
            }
          }

          #battery.critical:not(.charging) {
            ${defaultBackground}
            ${defaultColor}
            animation-name: blink;
            animation-duration: 0.5s;
            animation-timing-function: linear;
            animation-iteration-count: infinite;
            animation-direction: alternate;
          }

          #tray menu {
            ${padding}
          }

          #tray > .passive {
            -gtk-icon-effect: dim;
          }

          #tray > .needs-attention {
            -gtk-icon-effect: highlight;
            background-color: #eb4d4b;
          }
        '';
      };
    };
  };
}
