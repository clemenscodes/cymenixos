{
  inputs,
  pkgs,
  lib,
  ...
}: {
  config,
  osConfig,
  ...
}: let
  displayCfg = config.modules.display;
  cfg = displayCfg.compositor;
  machine = osConfig.modules.machine.kind;
  useHyprpicker = cfg.hyprland.hyprpicker.enable;
  useHyprsunset = cfg.hyprland.hyprsunset.enable;
  useKitty = config.modules.terminal.kitty.enable;
  useObs = config.modules.media.video.obs.enable;
  useMusic = config.modules.media.music.enable;
  useNcmpcpp = config.modules.media.music.ncmpcpp.enable;
  useScreenshots = displayCfg.screenshots.enable;
  useRofi = displayCfg.launcher.rofi.enable;
  useSwaync = displayCfg.notifications.swaync.enable;
  useWaybar = displayCfg.bar.waybar.enable;
  useBtop = config.modules.monitoring.btop.enable;
  useCalcurse = config.modules.organization.calcurse.enable;
  useEmail = config.modules.organization.email.enable;
  useThunderbird = config.modules.organization.email.thunderbird.enable;
  useLf = config.modules.explorer.lf.enable;
  useYazi = config.modules.explorer.yazi.enable;
  useNvim = config.modules.editor.nvim.enable;
  useFirefox = config.modules.browser.firefox.enable;
  useDavinci = config.modules.media.editing.davinci.enable;
  useBlueman = config.modules.networking.bluetooth.blueman.enable;
  useNm = config.modules.networking.nm.enable;
  useSwayidle = displayCfg.lockscreen.swayidle.enable;
  useSwayAudioIdle = displayCfg.lockscreen.sway-audio-idle-inhibit.enable;
  useSsh = config.modules.security.ssh.enable;
  useTorrent = osConfig.modules.networking.torrent.enable;
  useUdiskie = osConfig.modules.io.udisks.enable;
  useYubikey = osConfig.modules.security.yubikey.enable;
  useHyprlock = displayCfg.lockscreen.hyprlock.enable;
  useNewsboat = config.modules.media.rss.newsboat.enable;
  isLaptop = machine == "laptop";
  close-window = pkgs.writeShellScriptBin "close-window" ''
    if [ "$(${pkgs.hyprland}/bin/hyprctl activewindow -j | ${lib.getExe pkgs.jq} -r ".class")" = "Steam" ]; then
        ${lib.getExe pkgs.xdotool} getactivewindow windowunmap
    else
        ${pkgs.hyprland}/bin/hyprctl dispatch killactive ""
    fi
  '';
  random-wallpaper = import ./wallpaper {inherit inputs pkgs lib;};
in {
  imports = [
    (import ./hyprshade {inherit inputs pkgs lib;})
    (import ./hyprpicker {inherit inputs pkgs lib;})
    (import ./hyprsunset {inherit inputs pkgs lib;})
    (import ./xwayland {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      display = {
        compositor = {
          hyprland = {
            enable = lib.mkEnableOption "Enable anime titties" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.hyprland.enable) {
    home = {
      packages = [
        pkgs.brightnessctl
        pkgs.swww
        pkgs.wl-clipboard
        pkgs.cliphist
        (lib.mkIf isLaptop (import ./lidhandle {inherit inputs pkgs lib;}))
        random-wallpaper
      ];
    };
    wayland = {
      windowManager = {
        hyprland = {
          inherit (cfg.hyprland) enable;
          systemd = {
            enable = false;
          };
          settings = {
            input = {
              kb_layout = osConfig.modules.locale.defaultLocale;
              kb_options = "ctrl:nocaps";
              follow_mouse = 0;
              repeat_rate = 50;
              repeat_delay = 300;
              touchpad = {
                natural_scroll = "no";
              };
              sensitivity = 0;
              accel_profile = "flat";
            };

            general = {
              gaps_in = 6;
              gaps_out = 12;
              border_size = 2;
              "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
              "col.inactive_border" = "rgba(595959aa)";
              layout = "master";
            };

            decoration = {
              rounding = 4;
              blur = {
                enabled = true;
                size = 4;
                noise = 0.02;
                brightness = 0.9;
                contrast = 0.9;
                vibrancy = 0.2;
                vibrancy_darkness = 0.1;
                passes = 2;
                special = false;
              };
            };

            gestures = {
              workspace_swipe = "on";
              workspace_swipe_fingers = 3;
            };

            misc = {
              enable_swallow = true;
              disable_hyprland_logo = true;
              disable_splash_rendering = true;
              vrr = 1;
            };

            binds = {
              allow_workspace_cycles = true;
            };

            "$mod" = "SUPER";

            bind = [
              "$mod, F, fullscreen"
              "$mod, Q, exec, ${lib.getExe close-window}"
              "$mod, C, exec, hyprctl reload"
              "$mod, W, exec, ${config.modules.browser.defaultBrowser}"
              "$mod SHIFT, C, exit"
              "$mod SHIFT, F, togglefloating,"
              "$mod SHIFT, K, exec, hyprctl kill"
              "$mod SHIFT, W, exec, ${lib.getExe random-wallpaper}"
              "$mod, SPACE, layoutmsg, swapwithmaster"

              "$mod, 1, workspace, 1"
              "$mod, 2, workspace, 2"
              "$mod, 3, workspace, 3"
              "$mod, 4, workspace, 4"
              "$mod, 5, workspace, 5"
              "$mod, 6, workspace, 6"
              "$mod, 7, workspace, 7"
              "$mod, 8, workspace, 8"
              "$mod, 9, workspace, 9"
              "$mod, 0, workspace, 10"

              "$mod SHIFT, 1, movetoworkspace, 1"
              "$mod SHIFT, 2, movetoworkspace, 2"
              "$mod SHIFT, 3, movetoworkspace, 3"
              "$mod SHIFT, 4, movetoworkspace, 4"
              "$mod SHIFT, 5, movetoworkspace, 5"
              "$mod SHIFT, 6, movetoworkspace, 6"
              "$mod SHIFT, 7, movetoworkspace, 7"
              "$mod SHIFT, 8, movetoworkspace, 8"
              "$mod SHIFT, 9, movetoworkspace, 9"
              "$mod SHIFT, 0, movetoworkspace, 10"
              "$mod SHIFT, LEFT, movetoworkspace, -1"
              "$mod SHIFT, RIGHT, movetoworkspace, +1"
              "$mod SHIFT_R, 1, movetoworkspace, 1"
              "$mod SHIFT_R, 2, movetoworkspace, 2"
              "$mod SHIFT_R, 3, movetoworkspace, 3"
              "$mod SHIFT_R, 4, movetoworkspace, 4"
              "$mod SHIFT_R, 5, movetoworkspace, 5"
              "$mod SHIFT_R, 6, movetoworkspace, 6"
              "$mod SHIFT_R, 7, movetoworkspace, 7"
              "$mod SHIFT_R, 8, movetoworkspace, 8"
              "$mod SHIFT_R, 9, movetoworkspace, 9"
              "$mod SHIFT_R, 0, movetoworkspace, 10"
              "$mod SHIFT_R, LEFT, movetoworkspace, -1"
              "$mod SHIFT_R, RIGHT, movetoworkspace, +1"

              # Switch workspaces with mod + [0-9]
              # Move active window to a workspace with mod + SHIFT + [0-9]
              # Scroll through existing workspaces with mod + scroll
              "$mod, mouse_down, workspace, e+1"
              "$mod, mouse_up, workspace, e-1"

              (lib.mkIf useHyprpicker "$mod, U, exec, hyprpicker")
              (lib.mkIf useKitty "$mod, RETURN, exec, kitty -1 --title=kitty ")
              (lib.mkIf (useKitty && useNvim) "$mod, V, exec, kitty -1 --title=kitty nvim")
              (lib.mkIf (useKitty && useLf) "$mod, R, exec, kitty -1 --title=kitty lf")
              (lib.mkIf (useKitty && useYazi) "$mod, R, exec, kitty -1 --title=kitty yazi")
              (lib.mkIf (useKitty && useEmail) "$mod, E, exec, kitty -1 --title=kitty neomutt")
              (lib.mkIf (useKitty && useEmail && useThunderbird) "$mod SHIFT, E, exec, ${pkgs.thunderbird}/bin/thunderbird")
              (lib.mkIf (useKitty && useBtop) "$mod SHIFT, R, exec, kitty -1 --title=kitty btop")
              (lib.mkIf (useKitty && useNcmpcpp) "$mod, M, exec, kitty -1 --title=kitty ncmpcpp")
              (lib.mkIf (useKitty && useCalcurse) "$mod SHIFT, K, exec, kitty -1 --title=kitty calcurse")
              (lib.mkIf useNewsboat "$mod SHIFT, N, exec, kitty -1 --title=kitty newsboat")
              (lib.mkIf useWaybar "$mod, B, exec, waybar-toggle")
              (lib.mkIf useWaybar "$mod SHIFT, B, exec, waybar-reload")
              (lib.mkIf useSwaync "$mod, N, exec, swaync-client -t -sw")
              (lib.mkIf useRofi "$mod SHIFT, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy")
              (lib.mkIf useRofi "$mod, D, exec, rofi -show drun")
              (lib.mkIf useRofi "$mod, BACKSPACE, exec, logoutlaunch")
              (lib.mkIf useScreenshots "$mod, S, exec, screenshot")
              (lib.mkIf useScreenshots "$mod SHIFT, D, exec, fullscreenshot")
              (lib.mkIf useMusic "$mod, P, exec, mpc toggle")
              (lib.mkIf useMusic "$mod, COMMA, exec, mpc prev")
              (lib.mkIf useMusic ''$mod SHIFT, COMMA, exec, mpc seek "0%"'')
              (lib.mkIf useMusic "$mod, PERIOD, exec, mpc next")
              (lib.mkIf useMusic "$mod SHIFT, PERIOD, exec, mpc repeat")
              (lib.mkIf useObs "$mod, O, exec, obs --disable-shutdown-check --multi --startreplaybuffer")
              (lib.mkIf useObs "SHIFT, F8, pass,class:^(com\.obsproject\.Studio)$")
              (lib.mkIf useObs "SHIFT, F9, pass,class:^(com\.obsproject\.Studio)$")
              (lib.mkIf useObs "SHIFT, F10, pass,class:^(com\.obsproject\.Studio)$")
              (lib.mkIf useObs "SHIFT, F11, pass,class:^(com\.obsproject\.Studio)$")
              (lib.mkIf useMusic ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
              (lib.mkIf useMusic ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")
              (lib.mkIf useMusic ", XF86AudioAudioPrev, exec, mpc prev")
              (lib.mkIf useMusic ", XF86AudioAudioNext, exec, mpc next")
              (lib.mkIf useMusic ", XF86AudioAudioPause, exec, mpc pause")
              (lib.mkIf useMusic ", XF86AudioAudioPlay, exec, mpc play")
              (lib.mkIf useMusic ", XF86AudioAudioStop, exec, mpc stop")
              (lib.mkIf useMusic ", XF86AudioAudioRewind, exec, mpc seek -10")
              (lib.mkIf useMusic ", XF86AudioAudioForward, exec, mpc seek +10")
              (lib.mkIf isLaptop ", XF86MonBrightnessDown, exec, brightnessctl set 1%-")
              (lib.mkIf isLaptop ", XF86MonBrightnessUp, exec, brightnessctl set 1%+")
              (lib.mkIf isLaptop "SHIFT, XF86MonBrightnessDown, exec, brightnessctl set 5%-")
              (lib.mkIf isLaptop "SHIFT, XF86MonBrightnessUp, exec, brightnessctl set 5%+")
              (lib.mkIf (useMusic && useKitty) ", XF86AudioAudioMedia, exec, kitty -1 --title=kitty ncmpcpp")
              "$mod, P, togglespecialworkspace, magic"
              "$mod, P, movetoworkspace, +0"
              "$mod, P, togglespecialworkspace, magic"
              "$mod, P, movetoworkspace, special:magic"
              "$mod, P, togglespecialworkspace, magic"
            ];

            bindl = lib.mkIf isLaptop [
              ", switch:on:Lid Switch, exec, lidhandle on"
              ", switch:off:Lid Switch, exec, lidhandle off"
            ];

            binde = [
              # Move focus with vim keys
              "$mod, H, movefocus, l"
              "$mod, L, movefocus, r"
              "$mod, K, movefocus, u"
              "$mod, J, movefocus, d"
              "$mod ALT, H, movewindow, l"
              "$mod ALT, L, movewindow, r"
              "$mod ALT, K, movewindow, u"
              "$mod ALT, J, movewindow, d"
              "$mod SHIFT, L, resizeactive, 10 0"
              "$mod SHIFT, H, resizeactive, -10 0"
              "$mod SHIFT, K, resizeactive, 0 -10"
              "$mod SHIFT, J, resizeactive, 0 10"
              "$mod, LEFT, workspace, -1"
              "$mod, RIGHT, workspace, +1"

              (lib.mkIf useMusic ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+")
              (lib.mkIf useMusic ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")
            ];

            bindm = [
              "ALT, mouse:272, movewindow"
              "ALT, mouse:273, resizewindow"
            ];
          };
          extraConfig = let
            waybar =
              if useWaybar
              then "exec-once = waybar"
              else "";
            swaync =
              if useSwaync
              then "exec-once = swaync"
              else "";
            firefox =
              if useFirefox
              then ''
                windowrule = center 1,class:(firefox)
                windowrule = size 80% 80%,class:(firefox)
                windowrule = unset,title:^(.*)(Firefox)$
              ''
              else "";
            davinci =
              if useDavinci
              then ''
                windowrule = unset,class:(resolve),title:(resolve)
                windowrule = tile,title:^(DaVinci Resolve)(.*)$
              ''
              else "";
            blueman =
              if useBlueman
              then ''
                exec-once = blueman-applet
                windowrule = float,class:^(blueman-manager)$
              ''
              else "";
            nm =
              if useNm
              then ''
                exec-once = nm-applet --indicator
                windowrule = float,class:^(nm-applet)$
                windowrule = float,class:^(nm-connection-editor)$
              ''
              else "";
            torrent =
              if useTorrent
              then ''
                exec-once = mullvad-vpn
              ''
              else "";
            hypridle =
              if useHyprlock
              then ''
                exec-once = hypridle &
              ''
              else "";
            hyprsunset =
              if useHyprsunset
              then ''
                exec-once = hyprsunset &
              ''
              else "";
            kitty =
              if useKitty
              then ''
                windowrule = opacity 0.90,class:kitty
              ''
              else "";
            rofi =
              if useRofi
              then ''
                windowrule = float,class:Rofi
              ''
              else "";
            swayidle =
              if useSwayidle
              then ''
                exec-once = detectidle
              ''
              else "";
            swayaudioidle =
              if useSwayAudioIdle
              then ''
                exec-once = sway-audio-idle-inhibit
              ''
              else "";
            ssh =
              if useSsh
              then ''
                exec-once = sshagent
              ''
              else "";
            udiskie =
              if useUdiskie
              then ''
                exec-once = udiskie &
              ''
              else "";
            yubikey =
              if useYubikey
              then ''
                exec-once = ${pkgs.yubikey-touch-detector}/bin/yubikey-touch-detector -libnotify
              ''
              else "";
          in ''
            monitor = , highrr, auto, 1

            env = XCURSOR_SIZE,16
            env = XDG_SESSION_TYPE,wayland
            env = XDG_SESSION_DESKTOP,Hyprland
            env = XDG_CURRENT_DESKTOP,Hyprland
            env = MOZ_ENABLE_WAYLAND,1

            exec-once = ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd --all
            exec-once = ${pkgs.systemd}/bin/systemctl --user import-environment QT_QPA_PLATFORMTHEME
            exec-once = wl-paste --type text --watch cliphist store
            exec-once = wl-paste --type image --watch cliphist store
            exec-once = polkitagent
            exec-once = ${pkgs.swww}/bin/swww-daemon
            exec-once = wallpaper

            windowrule = float,class:^(org.kde.polkit-kde-authentication-agent-1)$

            ${kitty}
            ${rofi}
            ${waybar}
            ${swaync}
            ${swayidle}
            ${swayaudioidle}
            ${udiskie}
            ${ssh}
            ${firefox}
            ${davinci}
            ${blueman}
            ${nm}
            ${torrent}
            ${hypridle}
            ${hyprsunset}
            ${yubikey}
          '';
        };
      };
    };
  };
}
