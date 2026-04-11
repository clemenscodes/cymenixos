{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.gaming;
  hyprCfg = cfg.hyprland;

  # hypr-gamemode: manage Hyprland compositor effects for gaming.
  #
  #   hypr-gamemode on     — unconditionally disable animations/blur/shadow/gaps
  #   hypr-gamemode off    — unconditionally restore via hyprctl reload
  #   hypr-gamemode        — toggle based on current animations:enabled state
  #
  # The keybind uses the bare toggle. Hyprhook scripts use explicit on/off
  # so the state is always deterministic regardless of prior manual toggles.
  hyprGamemode = pkgs.writeShellApplication {
    name = "hypr-gamemode";
    runtimeInputs = [pkgs.hyprland pkgs.gawk];
    text = ''
      gamemode_on() {
        hyprctl --batch "
          keyword animations:enabled 0;
          keyword decoration:shadow:enabled 0;
          keyword decoration:blur:enabled 0;
          keyword general:gaps_in 0;
          keyword general:gaps_out 0;
          keyword general:border_size 1;
          keyword decoration:rounding 0"
      }

      gamemode_off() {
        hyprctl reload
      }

      case "''${1:-toggle}" in
        on)     gamemode_on ;;
        off)    gamemode_off ;;
        toggle)
          current=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')
          if [ "$current" = "1" ]; then gamemode_on; else gamemode_off; fi
          ;;
        *)
          echo "usage: hypr-gamemode [on|off|toggle]" >&2
          exit 1
          ;;
      esac
    '';
  };
in {
  options = {
    modules = {
      gaming = {
        hyprland = {
          enable = lib.mkEnableOption "Enable Hyprland gaming window rules and gamemode toggle" // {default = false;};
          gamemode = {
            keybind = lib.mkOption {
              type = lib.types.str;
              default = "F1";
              description = "Key (after \$mod) used to toggle Hyprland gamemode (disables animations, blur, shadows, gaps).";
            };
          };
        };
      };
    };
  };

  config = lib.mkIf (cfg.enable && hyprCfg.enable) {
    home-manager = lib.mkIf config.modules.home-manager.enable {
      users.${config.modules.users.user} = {
        home.packages = [hyprGamemode];

        wayland.windowManager.hyprland.settings = {
          windowrule = [
            # ── Steam Big Picture ──────────────────────────────────────────────
            # Send Big Picture mode to the games workspace and make it fullscreen
            # so it feels like a console UI rather than a floating Steam window.
            "workspace special:games, match:class ^(?i)steam$, match:title ^(?i).*Big Picture.*$"
            "fullscreen on, match:class ^(?i)steam$, match:title ^(?i).*Big Picture.*$"

            # ── Game clients ───────────────────────────────────────────────────
            # steam_app_* — windows spawned by Steam for individual game launches.
            # gamescope   — games that run inside a gamescope wrapper (e.g. RE Engine titles).
            #               CS2 is unaffected: it runs natively (no gamescope window) and has
            #               an explicit workspace 2 rule in cs2.nix that takes precedence.
            # sunshine    — game streaming server window.
            # proton/wine — Windows compatibility layer windows.
            "workspace special:games, match:class ^(?i)(steam_app_.*|gamescope|sunshine|proton|wine)$"
            "workspace special:games, match:initial_class ^(?i)(steam_app_.*|gamescope|sunshine|proton|wine)$"
            "fullscreen on, match:class ^(?i)(steam_app_.*|gamescope|sunshine|proton|wine)$"

            # ── Per-workspace compositor optimizations ─────────────────────────
            # Disabling these effects for the games workspace removes GPU memory-
            # bandwidth pressure during gameplay without touching any other workspace.
            "no_anim on, match:workspace special:games"
            "no_blur on, match:workspace special:games"
            "no_shadow on, match:workspace special:games"
            "decorate off, match:workspace special:games"
            "border_size 0, match:workspace special:games"
            "rounding 0, match:workspace special:games"
            "fullscreen on, match:workspace special:games"

            # ── Focus / input behaviour ────────────────────────────────────────
            # idle_inhibit: prevent screen lock while a game is active.
            # stay_focused: ignore focus-steal requests from background apps.
            # suppress activatefocus: drop _NET_ACTIVE_WINDOW requests from game processes.
            "idle_inhibit always, match:workspace special:games"
            "stay_focused on, match:workspace special:games"
            "suppress_event activatefocus, match:workspace special:games"
          ];

          bind = [
            "$mod, ${hyprCfg.gamemode.keybind}, exec, ${hyprGamemode}/bin/hypr-gamemode"
          ];
        };
      };
    };
  };
}
