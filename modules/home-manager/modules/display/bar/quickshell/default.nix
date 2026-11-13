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
  cfg = config.modules.display.bar;

  # 5-hour block token quotas per Claude Code plan tier.
  planQuotas = {
    pro = 19000;
    max5 = 88000;
    max20 = 220000;
  };
  claudeQuota =
    if cfg.waybar.claudeMonitor.quotaTokens != null
    then cfg.waybar.claudeMonitor.quotaTokens
    else planQuotas.${cfg.waybar.claudeMonitor.plan};
in {
  options = {
    modules = {
      display = {
        bar = {
          quickshell = {
            enable = lib.mkEnableOption "Enable Quickshell" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.quickshell.enable) {
    # NightLight keybinds. They go through Quickshell IPC so the pill stays in sync; the
    # reset falls back to hyprsunset directly, so it works even when Quickshell is down.
    wayland.windowManager.hyprland.extraConfig = lib.mkIf config.modules.display.compositor.hyprland.enable (let
      nl = fn: "${pkgs.quickshell}/bin/qs ipc -c cymenix call nightlight ${fn}";
      bind = keys: cmd: extra: "hl.bind(\"${keys}\", hl.dsp.exec_cmd(\"${cmd}\")${extra})";
    in ''
      -- Wake the display from NightLight's display off on any key or mouse movement
      hl.config({ misc = { key_press_enables_dpms = true, mouse_move_enables_dpms = true } })
      ${bind "SUPER + ALT + UP" (nl "brighter") ", { repeating = true }"}
      ${bind "SUPER + ALT + DOWN" (nl "darker") ", { repeating = true }"}
      ${bind "SUPER + ALT + LEFT" (nl "warmer") ", { repeating = true }"}
      ${bind "SUPER + ALT + RIGHT" (nl "cooler") ", { repeating = true }"}
      ${bind "SUPER + ALT + N" (nl "toggleWarm") ""}
      ${bind "SUPER + ALT + D" (nl "displayOff") ""}
      ${bind "SUPER + ALT + BACKSPACE" "sh -c '${nl "reset"} || { hyprctl hyprsunset identity; hyprctl hyprsunset gamma 100; }'" ""}
    '');
    home = {
      packages = [
        pkgs.libappindicator-gtk3
        pkgs.libdbusmenu-gtk3
        pkgs.brightnessctl
        # NightLight pill: colour temperature and software dimming via the Hyprland CTM protocol
        pkgs.hyprsunset
        pkgs.wtype
        pkgs.wl-clipboard
        (import ./helpers/qs-mail {inherit inputs pkgs lib;})
        (import ./helpers/qs-claude-monitor {
          inherit pkgs;
          quota = claudeQuota;
        })
        (import ./helpers/qs-nvidia {inherit pkgs;})
      ];
    };
    programs = {
      quickshell = {
        enable = true;
        package = pkgs.quickshell;
        configs = {
          cymenix = ./qml;
        };
        activeConfig = "cymenix";
        systemd = {
          enable = true;
          target = "hyprland-session.target";
        };
      };
    };
  };
}
