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
            lib.mkEnableOption "Enable Hyprland gamemode toggle"
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
          -- Gamemode toggle
          hl.bind("SUPER + ${hyprCfg.gamemode.keybind}", hl.dsp.exec_cmd("${hypr-gamemode}/bin/hypr-gamemode"))
        '';
      };
    };
  };
}
