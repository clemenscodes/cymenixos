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
  hypr-gamemode = pkgs.writeShellApplication {
    name = "hypr-gamemode";
    runtimeInputs = [
      pkgs.hyprland
      pkgs.gawk
    ];
    text = ''
      is_on() {
        [ "$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')" = "0" ]
      }

      gamemode_on() {
        if is_on; then return 0; fi
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
        if ! is_on; then return 0; fi
        hyprctl reload
      }

      case "''${1:-toggle}" in
        on)     gamemode_on ;;
        off)    gamemode_off ;;
        toggle) if is_on; then gamemode_off; else gamemode_on; fi ;;
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
          enable =
            lib.mkEnableOption "Enable Hyprland gaming window rules and gamemode toggle"
            // {
              default = false;
            };
          gamemode = {
            keybind = lib.mkOption {
              type = lib.types.str;
              default = "F1";
              description = "Key (after \$mod) used to toggle Hyprland gamemode (disables animations, blur, shadows, gaps).";
            };
          };
          scripts = {
            hypr-gamemode = lib.mkOption {
              type = lib.types.package;
              readOnly = true;
              description = "The hypr-gamemode script derivation.";
            };
          };
        };
      };
    };
  };

  config = lib.mkIf (cfg.enable && hyprCfg.enable) {
    modules.gaming.hyprland.scripts = {inherit hypr-gamemode;};

    home-manager = lib.mkIf config.modules.home-manager.enable {
      users.${config.modules.users.user} = {
        home.packages = [hypr-gamemode];

        wayland.windowManager.hyprland.extraConfig = ''
          -- Steam Big Picture: send to games workspace and fullscreen
          hl.window_rule({ match = { class = "^(?i)steam$", title = "^(?i).*Big Picture.*$" }, workspace = "special:games" })
          hl.window_rule({ match = { class = "^(?i)steam$", title = "^(?i).*Big Picture.*$" }, fullscreen = true })

          -- Game clients (steam_app_*, gamescope, sunshine, proton, wine)
          -- CS2 runs natively and has an explicit workspace 2 rule in cs2.nix that takes precedence.
          hl.window_rule({ match = { class = "^(?i)(steam_app_.*|gamescope|sunshine|proton|wine)$" }, workspace = "special:games" })
          hl.window_rule({ match = { initial_class = "^(?i)(steam_app_.*|gamescope|sunshine|proton|wine)$" }, workspace = "special:games" })
          hl.window_rule({ match = { class = "^(?i)(steam_app_.*|gamescope|sunshine|proton|wine)$" }, fullscreen = true })

          -- Per-workspace compositor optimizations and input behaviour for special:games
          hl.window_rule({ match = { workspace = "special:games" },
            no_anim = true, no_blur = true, no_shadow = true,
            decorate = false, border_size = 0, rounding = 0, fullscreen = true,
            idle_inhibit = "always", stay_focused = true, suppress_event = "activatefocus" })

          -- Gamemode toggle
          hl.bind("SUPER + ${hyprCfg.gamemode.keybind}", hl.dsp.exec_cmd("${hypr-gamemode}/bin/hypr-gamemode"))
        '';
      };
    };
  };
}
