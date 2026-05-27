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
  useMusic = config.modules.media.music.enable;
  useNcmpcpp = config.modules.media.music.ncmpcpp.enable;
  useScreenshots = displayCfg.screenshots.enable;
  useRofi = displayCfg.launcher.rofi.enable;
  useAnyrun = displayCfg.launcher.anyrun.enable;
  useSwaync = displayCfg.notifications.swaync.enable;
  useWaybar = displayCfg.bar.waybar.enable;
  useBtop = config.modules.monitoring.btop.enable;
  useCalcurse = config.modules.organization.calcurse.enable;
  useEmail = config.modules.organization.email.enable;
  useThunderbird = config.modules.organization.email.thunderbird.enable;
  useLf = config.modules.explorer.lf.enable;
  useGnomeKeyring = osConfig.modules.security.gnome-keyring.enable;
  useEvglow = osConfig.services.evglow.enable;
  useHyprhook = osConfig.modules.io.enable && osConfig.modules.io.hyprhook.enable && (inputs ? hyprhook);
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
  # Convert "OUTPUT, MODE, POSITION, SCALE" string to a hl.monitor({}) Lua call
  monitorToLua = m: let
    parts = lib.splitString ", " m;
    output = lib.elemAt parts 0;
    mode = lib.elemAt parts 1;
    position = lib.elemAt parts 2;
    scale = lib.elemAt parts 3;
  in ''hl.monitor({ output = "${output}", mode = "${mode}", position = "${position}", scale = ${scale} })'';
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
            enable =
              lib.mkEnableOption "Enable anime titties"
              // {default = false;};
            monitors = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
              description = ''
                Extra monitor rules prepended before the catch-all.
                Each entry: "OUTPUT, MODE, POSITION, SCALE"
                e.g. "HDMI-A-2, 3840x2160@60, 0x0, 1"
              '';
              example = ["HDMI-A-2, 3840x2160@60, 0x0, 1"];
            };
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.hyprland.enable) {
    home.packages = [
      pkgs.brightnessctl
      pkgs.awww
      pkgs.wl-clipboard
      pkgs.cliphist
      (lib.mkIf isLaptop (import ./lidhandle {inherit inputs pkgs lib;}))
      random-wallpaper
    ];
    wayland.windowManager.hyprland = {
      inherit (cfg.hyprland) enable;
      configType = "lua";
      systemd.enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;

      # Rendered as hl.config({...}) in the generated hyprland.lua
      settings.config = {
        input = {
          kb_layout = osConfig.modules.locale.defaultLocale;
          kb_options = "ctrl:nocaps";
          follow_mouse = 0;
          repeat_rate = 50;
          repeat_delay = 300;
          touchpad.natural_scroll = false;
          sensitivity = 0;
          accel_profile = "flat";
        };
        general = {
          gaps_in = 6;
          gaps_out = 12;
          border_size = 2;
          col = {
            active_border = lib.generators.mkLuaInline ''{ colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 }'';
            inactive_border = "rgba(595959aa)";
          };
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
        misc = {
          enable_swallow = true;
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          vrr = 1;
        };
        binds.allow_workspace_cycles = true;
        ecosystem.no_update_news = true;
      };

      extraConfig = ''
        local mod = "SUPER"

        -- Environment
        hl.env("XCURSOR_SIZE", "16")
        hl.env("XDG_SESSION_TYPE", "wayland")
        hl.env("XDG_SESSION_DESKTOP", "Hyprland")
        hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
        hl.env("MOZ_ENABLE_WAYLAND", "1")

        -- Monitors (custom rules first, catch-all last: highrr, auto-position, 1x scale)
        ${lib.concatMapStrings (m: "${monitorToLua m}\n") cfg.hyprland.monitors}hl.monitor({ output = "", mode = "highrr", position = "auto", scale = 1 })

        -- Startup
        hl.on("hyprland.start", function()
          hl.exec_cmd("${pkgs.dbus}/bin/dbus-update-activation-environment --systemd --all")
          hl.exec_cmd("${pkgs.systemd}/bin/systemctl --user import-environment QT_QPA_PLATFORMTHEME")
          hl.exec_cmd("wl-paste --type text --watch cliphist store")
          hl.exec_cmd("wl-paste --type image --watch cliphist store")
          hl.exec_cmd("polkitagent")
          hl.exec_cmd("${pkgs.awww}/bin/awww-daemon")
          hl.exec_cmd("wallpaper")
          ${lib.optionalString useWaybar        ''hl.exec_cmd("waybar")''}
          ${lib.optionalString useSwaync        ''hl.exec_cmd("swaync")''}
          ${lib.optionalString useSwayidle      ''hl.exec_cmd("detectidle")''}
          ${lib.optionalString useSwayAudioIdle ''hl.exec_cmd("sway-audio-idle-inhibit")''}
          ${lib.optionalString useSsh           ''hl.exec_cmd("sshagent")''}
          ${lib.optionalString useBlueman       ''hl.exec_cmd("blueman-applet")''}
          ${lib.optionalString useNm            ''hl.exec_cmd("nm-applet --indicator")''}
          ${lib.optionalString useTorrent       ''hl.exec_cmd("mullvad-vpn")''}
          ${lib.optionalString useHyprlock      ''hl.exec_cmd("hypridle")''}
          ${lib.optionalString useHyprsunset    ''hl.exec_cmd("hyprsunset")''}
          ${lib.optionalString useYubikey       ''hl.exec_cmd("${pkgs.yubikey-touch-detector}/bin/yubikey-touch-detector -libnotify")''}
          ${lib.optionalString useGnomeKeyring  ''hl.exec_cmd("unlock-keyring")''}
          ${lib.optionalString useEvglow        ''hl.exec_cmd("evglow")''}
          ${lib.optionalString useHyprhook      ''hl.exec_cmd("${osConfig.services.hyprhook.finalPackage}/bin/hyprhook")''}
        end)

        -- Window rules
        hl.window_rule({ match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" }, float = true })
        hl.window_rule({ match = { class = "^(gamescope)$", title = "^(Counter-Strike 2)$" },
          fullscreen = true, stay_focused = true, immediate = true })
        ${lib.optionalString useKitty   ''hl.window_rule({ match = { class = "kitty" }, opacity = 0.90 })''}
        ${lib.optionalString useRofi    ''hl.window_rule({ match = { class = "Rofi" }, float = true })''}
        ${lib.optionalString useBlueman ''hl.window_rule({ match = { class = "^(blueman-manager)$" }, float = true })''}
        ${lib.optionalString useNm ''
        hl.window_rule({ match = { class = "^(nm-applet)$" }, float = true })
        hl.window_rule({ match = { class = "^(nm-connection-editor)$" }, float = true })
        ''}
        ${lib.optionalString useFirefox ''hl.window_rule({ match = { class = "firefox" }, center = true })''}
        ${lib.optionalString useDavinci ''hl.window_rule({ match = { title = "^(DaVinci Resolve)(.*)$" }, tile = true })''}

        -- Passthru submap: forwards $mod to the focused window (e.g. for VMs, remote desktops)
        hl.define_submap("passthru", "reset", function()
          hl.bind(mod .. " + SHIFT + Q", hl.dsp.submap("reset"))
        end)

        -- Core binds
        hl.bind(mod .. " + F",       hl.dsp.window.fullscreen())
        hl.bind(mod .. " + Q",       hl.dsp.exec_cmd("${lib.getExe close-window}"))
        hl.bind(mod .. " + C",       hl.dsp.exec_cmd("hyprctl reload"))
        hl.bind(mod .. " + W",       hl.dsp.exec_cmd("${config.modules.browser.defaultBrowser}"))
        hl.bind(mod .. " + SHIFT + C", hl.dsp.exit())
        hl.bind(mod .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))
        hl.bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd("${lib.getExe random-wallpaper}"))
        hl.bind(mod .. " + SHIFT + Q", hl.dsp.submap("passthru"))
        hl.bind(mod .. " + SPACE",   hl.dsp.layout("swapwithmaster"))

        -- Workspace navigation (loop for 1–9, manual for 10)
        for i = 1, 9 do
          hl.bind(mod .. " + " .. i,       hl.dsp.focus({ workspace = i }))
          hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
        end
        hl.bind(mod .. " + 0",           hl.dsp.focus({ workspace = 10 }))
        hl.bind(mod .. " + SHIFT + 0",     hl.dsp.window.move({ workspace = 10 }))
        hl.bind(mod .. " + SHIFT + LEFT",  hl.dsp.window.move({ workspace = "e-1" }))
        hl.bind(mod .. " + SHIFT + RIGHT", hl.dsp.window.move({ workspace = "e+1" }))
        hl.bind(mod .. " + LEFT",  hl.dsp.focus({ workspace = "e-1" }), { repeating = true })
        hl.bind(mod .. " + RIGHT", hl.dsp.focus({ workspace = "e+1" }), { repeating = true })
        hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
        hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

        -- Focus movement (vim keys, repeating)
        hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }),  { repeating = true })
        hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }), { repeating = true })
        hl.bind(mod .. " + K", hl.dsp.focus({ direction = "up" }),    { repeating = true })
        hl.bind(mod .. " + J", hl.dsp.focus({ direction = "down" }),  { repeating = true })

        -- Move windows in tiling (repeating)
        hl.bind(mod .. " + ALT + H", hl.dsp.window.move({ direction = "left" }),  { repeating = true })
        hl.bind(mod .. " + ALT + L", hl.dsp.window.move({ direction = "right" }), { repeating = true })
        hl.bind(mod .. " + ALT + K", hl.dsp.window.move({ direction = "up" }),    { repeating = true })
        hl.bind(mod .. " + ALT + J", hl.dsp.window.move({ direction = "down" }),  { repeating = true })

        -- Resize active window (repeating)
        hl.bind(mod .. " + SHIFT + L", hl.dsp.window.resize({ x = 10,  y = 0,   relative = true }), { repeating = true })
        hl.bind(mod .. " + SHIFT + H", hl.dsp.window.resize({ x = -10, y = 0,   relative = true }), { repeating = true })
        hl.bind(mod .. " + SHIFT + K", hl.dsp.window.resize({ x = 0,   y = -10, relative = true }), { repeating = true })
        hl.bind(mod .. " + SHIFT + J", hl.dsp.window.resize({ x = 0,   y = 10,  relative = true }), { repeating = true })

        -- Mouse: drag/resize with Alt+click
        hl.bind("ALT + mouse:272", hl.dsp.window.drag(),   { mouse = true })
        hl.bind("ALT + mouse:273", hl.dsp.window.resize(), { mouse = true })

        -- Magic special workspace on ` (backtick); $mod+P is now free for music
        hl.bind(mod .. " + grave", function()
          hl.dispatch(hl.dsp.workspace.toggle_special("magic"))
          hl.dispatch(hl.dsp.window.move({ workspace = "+0" }))
          hl.dispatch(hl.dsp.workspace.toggle_special("magic"))
          hl.dispatch(hl.dsp.window.move({ workspace = "special:magic" }))
          hl.dispatch(hl.dsp.workspace.toggle_special("magic"))
        end)

        -- Lid switch + brightness keys (laptop only)
        ${lib.optionalString isLaptop ''
        hl.bind("switch:on:Lid Switch",  hl.dsp.exec_cmd("lidhandle on"),  { locked = true })
        hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("lidhandle off"), { locked = true })
        hl.bind("XF86MonBrightnessDown",       hl.dsp.exec_cmd("brightnessctl set 1%-"))
        hl.bind("XF86MonBrightnessUp",         hl.dsp.exec_cmd("brightnessctl set 1%+"))
        hl.bind("SHIFT + XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"))
        hl.bind("SHIFT + XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set 5%+"))
        ''}

        -- Application binds
        ${lib.optionalString useHyprpicker                               ''hl.bind(mod .. " + U",        hl.dsp.exec_cmd("hyprpicker"))''}
        ${lib.optionalString useKitty                                    ''hl.bind(mod .. " + RETURN",   hl.dsp.exec_cmd("kitty -1 --title=kitty"))''}
        ${lib.optionalString (useKitty && useNvim)                       ''hl.bind(mod .. " + V",        hl.dsp.exec_cmd("kitty -1 --title=kitty nvim"))''}
        ${lib.optionalString (useKitty && useYazi)                       ''hl.bind(mod .. " + R",        hl.dsp.exec_cmd("kitty -1 --title=kitty yazi"))''}
        ${lib.optionalString (useKitty && !useYazi && useLf)             ''hl.bind(mod .. " + R",        hl.dsp.exec_cmd("kitty -1 --title=kitty lf"))''}
        ${lib.optionalString (useKitty && useEmail)                      ''hl.bind(mod .. " + E",        hl.dsp.exec_cmd("kitty -1 --title=kitty neomutt"))''}
        ${lib.optionalString (useKitty && useEmail && useThunderbird)    ''hl.bind(mod .. " + SHIFT + E",  hl.dsp.exec_cmd("${pkgs.thunderbird}/bin/thunderbird"))''}
        ${lib.optionalString (useKitty && useBtop)                       ''hl.bind(mod .. " + SHIFT + R",  hl.dsp.exec_cmd("kitty -1 --title=kitty btop"))''}
        ${lib.optionalString (useKitty && useNcmpcpp)                    ''hl.bind(mod .. " + M",        hl.dsp.exec_cmd("kitty -1 --title=kitty ncmpcpp"))''}
        ${lib.optionalString (useKitty && useCalcurse)                   ''hl.bind(mod .. " + ALT + K",    hl.dsp.exec_cmd("kitty -1 --title=kitty calcurse"))''}
        ${lib.optionalString useNewsboat                                  ''hl.bind(mod .. " + SHIFT + N",  hl.dsp.exec_cmd("kitty -1 --title=kitty newsboat"))''}
        ${lib.optionalString useWaybar ''
        hl.bind(mod .. " + B",       hl.dsp.exec_cmd("waybar-toggle"))
        hl.bind(mod .. " + SHIFT + B", hl.dsp.exec_cmd("waybar-reload"))
        ''}
        ${lib.optionalString useSwaync ''hl.bind(mod .. " + N",        hl.dsp.exec_cmd("swaync-client -t -sw"))''}
        ${lib.optionalString useRofi   ''hl.bind(mod .. " + SHIFT + V",  hl.dsp.exec_cmd("cliphist list | rofi -dmenu | cliphist decode | wl-copy"))''}
        ${lib.optionalString useAnyrun ''hl.bind(mod .. " + D",        hl.dsp.exec_cmd("anyrun"))''}
        ${lib.optionalString useRofi   ''hl.bind(mod .. " + BACKSPACE", hl.dsp.exec_cmd("logoutlaunch"))''}
        ${lib.optionalString useScreenshots ''
        hl.bind(mod .. " + S",       hl.dsp.exec_cmd("screenshot"))
        hl.bind(mod .. " + SHIFT + D", hl.dsp.exec_cmd("fullscreenshot"))
        ''}

        -- Music / audio binds
        ${lib.optionalString useMusic ''
        hl.bind(mod .. " + P",            hl.dsp.exec_cmd("mpc toggle"))
        hl.bind(mod .. " + COMMA",        hl.dsp.exec_cmd("mpc prev"))
        hl.bind(mod .. " + SHIFT + COMMA",  hl.dsp.exec_cmd("mpc seek 0%"))
        hl.bind(mod .. " + PERIOD",       hl.dsp.exec_cmd("mpc next"))
        hl.bind(mod .. " + SHIFT + PERIOD", hl.dsp.exec_cmd("mpc repeat"))
        hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
        hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
        hl.bind("XF86AudioPrev",        hl.dsp.exec_cmd("mpc prev"))
        hl.bind("XF86AudioNext",        hl.dsp.exec_cmd("mpc next"))
        hl.bind("XF86AudioPause",       hl.dsp.exec_cmd("mpc pause"))
        hl.bind("XF86AudioPlay",        hl.dsp.exec_cmd("mpc play"))
        hl.bind("XF86AudioStop",        hl.dsp.exec_cmd("mpc stop"))
        hl.bind("XF86AudioRewind",      hl.dsp.exec_cmd("mpc seek -10"))
        hl.bind("XF86AudioForward",     hl.dsp.exec_cmd("mpc seek +10"))
        hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })
        hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        { repeating = true })
        ${lib.optionalString (useKitty && useNcmpcpp) ''hl.bind("XF86AudioMedia", hl.dsp.exec_cmd("kitty -1 --title=kitty ncmpcpp"))''}
        ''}
      '';
    };
    # Route ScreenCast to xdg-desktop-portal-hyprland, FileChooser to gtk
    xdg.portal.config.hyprland = {
      default = ["hyprland" "gtk"];
      "org.freedesktop.portal.FileChooser" = ["gtk"];
    };
  };
}
