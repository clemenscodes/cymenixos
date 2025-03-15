{
  inputs,
  pkgs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.gaming.battlenet;
  inherit (config.modules.users) name;
  warcraft = pkgs.writeShellApplication {
    name = "warcraft";
    runtimeInputs = [
      inputs.battlenet.packages.${system}.battlenet
      warcraft-mode-start
      warcraft-mode-stop
    ];
    text = ''
      warcraft-mode-start
      battlenet
      warcraft-mode-stop
    '';
  };
  warcraft-mode-start = pkgs.writeShellApplication {
    name = "warcraft-mode-start";
    runtimeInputs = [
      pkgs.hyprland
    ];
    text = ''
      hyprctl dispatch submap WARCRAFT
    '';
  };
  warcraft-mode-stop = pkgs.writeShellApplication {
    name = "warcraft-mode-stop";
    runtimeInputs = [
      pkgs.hyprland
    ];
    text = ''
      hyprctl dispatch submap reset
    '';
  };
  warcraft-chat-open = pkgs.writeShellApplication {
    name = "warcraft-chat-open";
    runtimeInputs = [
      pkgs.hyprland
    ];
    text = ''
      ydotool key 96:1 96:0
      hyprctl dispatch submap CHAT
    '';
  };
  warcraft-chat-send = pkgs.writeShellApplication {
    name = "warcraft-chat-send";
    runtimeInputs = [
      pkgs.hyprland
    ];
    text = ''
      ydotool key 96:1 96:0
      hyprctl dispatch submap WARCRAFT
    '';
  };
  warcraft-chat-close = pkgs.writeShellApplication {
    name = "warcraft-chat-close";
    runtimeInputs = [
      pkgs.hyprland
      pkgs.ydotool
    ];
    text = ''
      ydotool key 1:1 1:0
      hyprctl dispatch submap WARCRAFT
    '';
  };
  warcraft-autocast-hotkey = pkgs.writeShellApplication {
    name = "warcraft-autocast-hotkey";
    runtimeInputs = [
      pkgs.ydotool
      pkgs.hyprland
    ];
    text = ''
      YDOTOOL_LOG_FILE="$WARCRAFT_HOME/ydotool_log"
      SCREEN_WIDTH=1920
      SCREEN_HEIGHT=1080

      while [[ $# -gt 0 ]]; do
        case "$1" in
          --width)
            SCREEN_WIDTH="$2"
            shift 2
            ;;
          --height)
            SCREEN_HEIGHT="$2"
            shift 2
            ;;
          *)
            HOTKEY="$1"
            shift
            ;;
        esac
      done

      echo "Activating autocast hotkey $HOTKEY" >> "$YDOTOOL_LOG_FILE"

      MOUSE_POS=$(hyprctl cursorpos)
      MOUSE_X=$(echo "$MOUSE_POS" | cut -d' ' -f1 | cut -d',' -f1)
      MOUSE_Y=$(echo "$MOUSE_POS" | cut -d' ' -f2)

      case "$HOTKEY" in
        Q) X=$((SCREEN_WIDTH * 72 / 100)); Y=$((SCREEN_HEIGHT * 80 / 100)); return ;;
        W) X=$((SCREEN_WIDTH * 76 / 100)); Y=$((SCREEN_HEIGHT * 80 / 100)); return ;;
        E) X=$((SCREEN_WIDTH * 80 / 100)); Y=$((SCREEN_HEIGHT * 80 / 100)); return ;;
        R) X=$((SCREEN_WIDTH * 84 / 100)); Y=$((SCREEN_HEIGHT * 80 / 100)); return ;;
        A) X=$((SCREEN_WIDTH * 72 / 100)); Y=$((SCREEN_HEIGHT * 87 / 100)); return ;;
        S) X=$((SCREEN_WIDTH * 76 / 100)); Y=$((SCREEN_HEIGHT * 87 / 100)); return ;;
        D) X=$((SCREEN_WIDTH * 80 / 100)); Y=$((SCREEN_HEIGHT * 87 / 100)); return ;;
        F) X=$((SCREEN_WIDTH * 84 / 100)); Y=$((SCREEN_HEIGHT * 87 / 100)); return ;;
        Y) X=$((SCREEN_WIDTH * 72 / 100)); Y=$((SCREEN_HEIGHT * 94 / 100)); return ;;
        X) X=$((SCREEN_WIDTH * 76 / 100)); Y=$((SCREEN_HEIGHT * 94 / 100)); return ;;
        C) X=$((SCREEN_WIDTH * 80 / 100)); Y=$((SCREEN_HEIGHT * 94 / 100)); return ;;
        V) X=$((SCREEN_WIDTH * 84 / 100)); Y=$((SCREEN_HEIGHT * 94 / 100)); return ;;
      esac

      MOUSE_X=$((MOUSE_X / 2))
      MOUSE_Y=$((MOUSE_Y / 2))
      X=$((X / 2))
      Y=$((Y / 2))

      echo "Moving mouse to coordinate $X x $Y and clicking right mouse button" >> "$YDOTOOL_LOG_FILE"

      ydotool mousemove --absolute --xpos 0 --ypos 0
      ydotool mousemove --xpos "$X" --ypos "$Y"
      ydotool click 0xC1
      ydotool mousemove --absolute --xpos 0 --ypos 0
      ydotool mousemove --xpos "$MOUSE_X" --ypos "$MOUSE_Y"
    '';
  };
  warcraft-inventory-hotkey = pkgs.writeShellApplication {
    name = "warcraft-inventory-hotkey";
    runtimeInputs = [
      pkgs.ydotool
      pkgs.hyprland
    ];
    text = ''
      YDOTOOL_LOG_FILE="$WARCRAFT_HOME/ydotool_log"
      SCREEN_WIDTH=1920
      SCREEN_HEIGHT=1080

      while [[ $# -gt 0 ]]; do
        case "$1" in
          --width)
            SCREEN_WIDTH="$2"
            shift 2
            ;;
          --height)
            SCREEN_HEIGHT="$2"
            shift 2
            ;;
          *)
            HOTKEY="$1"
            shift
            ;;
        esac
      done

      echo "Activating inventory hotkey $HOTKEY" >> "$YDOTOOL_LOG_FILE"

      MOUSE_POS=$(hyprctl cursorpos)
      MOUSE_X=$(echo "$MOUSE_POS" | cut -d' ' -f1 | cut -d',' -f1)
      MOUSE_Y=$(echo "$MOUSE_POS" | cut -d' ' -f2)

      case "$HOTKEY" in
        1) X=$((SCREEN_WIDTH * 79 / 128)); Y=$((SCREEN_HEIGHT * 89 / 108)); return ;;
        2) X=$((SCREEN_WIDTH * 21 / 32)); Y=$((SCREEN_HEIGHT * 89 / 108)); return ;;
        3) X=$((SCREEN_WIDTH * 79 / 128)); Y=$((SCREEN_HEIGHT * 8 / 9)); return ;;
        4) X=$((SCREEN_WIDTH * 21 / 32)); Y=$((SCREEN_HEIGHT * 8 / 9)); return ;;
        5) X=$((SCREEN_WIDTH * 79 / 128)); Y=$((SCREEN_HEIGHT * 205 / 216)); return ;;
        6) X=$((SCREEN_WIDTH * 21 / 32)); Y=$((SCREEN_HEIGHT * 205 / 216)); return ;;
      esac

      MOUSE_X=$((MOUSE_X / 2))
      MOUSE_Y=$((MOUSE_Y / 2))
      X=$((X / 2))
      Y=$((Y / 2))

      echo "Moving mouse to coordinate $X x $Y and clicking left mouse button" >> "$YDOTOOL_LOG_FILE"

      ydotool mousemove --absolute --xpos 0 --ypos 0
      ydotool mousemove --xpos "$X" --ypos "$Y"
      ydotool click 0xC0
      ydotool mousemove --absolute --xpos 0 --ypos 0
      ydotool mousemove --xpos "$MOUSE_X" --ypos "$MOUSE_Y"
    '';
  };
  warcraft-write-control-group = pkgs.writeShellApplication {
    name = "warcraft-write-control-group";
    excludeShellChecks = ["SC2046" "SC2086"];
    runtimeInputs = [
      pkgs.ydotool
      pkgs.hyprland
    ];
    text = ''
      hyprctl dispatch submap CONTROLGROUP

      YDOTOOL_LOG_FILE="$WARCRAFT_HOME/ydotool_log"
      CONTROL_GROUP="$1"

      echo "$CONTROL_GROUP" > "$WARCRAFT_HOME/control_group"

      case "$CONTROL_GROUP" in
        1) CONTROL_GROUP_KEYCODE=2 ;;
        2) CONTROL_GROUP_KEYCODE=3 ;;
        3) CONTROL_GROUP_KEYCODE=4 ;;
        4) CONTROL_GROUP_KEYCODE=5 ;;
        5) CONTROL_GROUP_KEYCODE=6 ;;
        6) CONTROL_GROUP_KEYCODE=7 ;;
        7) CONTROL_GROUP_KEYCODE=8 ;;
        8) CONTROL_GROUP_KEYCODE=9 ;;
        9) CONTROL_GROUP_KEYCODE=10 ;;
        0) CONTROL_GROUP_KEYCODE=11 ;;
      esac

      echo "Selecting control group $CONTROL_GROUP" >> "$YDOTOOL_LOG_FILE"
      echo "Writing control group keycode" >> "YDOTOOL_LOG_FILE"
      echo "$CONTROL_GROUP_KEYCODE" > "$WARCRAFT_HOME/control_group_keycode"

      sleep 0.1

      ydotool key "$CONTROL_GROUP_KEYCODE":1 "$CONTROL_GROUP_KEYCODE":0

      hyprctl dispatch submap WARCRAFT
    '';
  };
  warcraft-create-control-group = pkgs.writeShellApplication {
    name = "warcraft-create-control-group";
    excludeShellChecks = ["SC2046" "SC2086"];
    runtimeInputs = [
      pkgs.ydotool
      pkgs.hyprland
    ];
    text = ''
      hyprctl dispatch submap CONTROLGROUP

      YDOTOOL_LOG_FILE="$WARCRAFT_HOME/ydotool_log"
      CONTROL_GROUP="$1"

      echo "$CONTROL_GROUP" > "$WARCRAFT_HOME/control_group"

      case "$CONTROL_GROUP" in
        1) CONTROL_GROUP_KEYCODE=2 ;;
        2) CONTROL_GROUP_KEYCODE=3 ;;
        3) CONTROL_GROUP_KEYCODE=4 ;;
        4) CONTROL_GROUP_KEYCODE=5 ;;
        5) CONTROL_GROUP_KEYCODE=6 ;;
        6) CONTROL_GROUP_KEYCODE=7 ;;
        7) CONTROL_GROUP_KEYCODE=8 ;;
        8) CONTROL_GROUP_KEYCODE=9 ;;
        9) CONTROL_GROUP_KEYCODE=10 ;;
        0) CONTROL_GROUP_KEYCODE=11 ;;
      esac

      echo "Creating control group $CONTROL_GROUP" >> "$YDOTOOL_LOG_FILE"
      echo "Writing control group keycode" >> "YDOTOOL_LOG_FILE"
      echo "$CONTROL_GROUP_KEYCODE" > "$WARCRAFT_HOME/control_group_keycode"

      sleep 0.1

      ydotool key 29:1 "$CONTROL_GROUP_KEYCODE":1 "$CONTROL_GROUP_KEYCODE":0 29:0

      hyprctl dispatch submap WARCRAFT
    '';
  };
  warcraft-edit-unit-control-group = pkgs.writeShellApplication {
    name = "warcraft-edit-unit-control-group";
    runtimeInputs = [
      pkgs.ydotool
      pkgs.hyprland
    ];
    excludeShellChecks = ["SC2046" "SC2086"];
    text = ''
      YDOTOOL_LOG_FILE="$WARCRAFT_HOME/ydotool_log"
      CONTROL_GROUP_KEYCODE_FILE="$WARCRAFT_HOME/control_group_keycode"
      CONTROL_GROUP_KEYCODE="$(cat "$CONTROL_GROUP_KEYCODE_FILE")"

      echo "Editing unit from control group" >> "$YDOTOOL_LOG_FILE"

      hyprctl dispatch submap CONTROLGROUP

      sleep 0.1

      ydotool key 42:1
      ydotool click 0xC0
      ydotool key 42:0
      ydotool key 29:1 "$CONTROL_GROUP_KEYCODE":1 "$CONTROL_GROUP_KEYCODE":0 29:0

      hyprctl dispatch submap WARCRAFT
    '';
  };
  warcraft-select-unit = pkgs.writeShellApplication {
    name = "warcraft-select-unit";
    runtimeInputs = [
      pkgs.ydotool
      pkgs.hyprland
    ];
    excludeShellChecks = ["SC2046" "SC2086"];
    text = ''
      YDOTOOL_LOG_FILE="$WARCRAFT_HOME/ydotool_log"
      SCREEN_WIDTH=1920
      SCREEN_HEIGHT=1080

      while [[ $# -gt 0 ]]; do
        case "$1" in
          --width)
            SCREEN_WIDTH="$2"
            shift 2
            ;;
          --height)
            SCREEN_HEIGHT="$2"
            shift 2
            ;;
          *)
            SELECTED_UNIT="$1"
            shift
            ;;
        esac
      done

      echo "Selecting unit $SELECTED_UNIT from current control group" >> "$YDOTOOL_LOG_FILE"

      MOUSE_POS=$(hyprctl cursorpos)
      MOUSE_X=$(echo "$MOUSE_POS" | cut -d' ' -f1 | cut -d',' -f1)
      MOUSE_Y=$(echo "$MOUSE_POS" | cut -d' ' -f2)

      case "$SELECTED_UNIT" in
        1) X=$((SCREEN_WIDTH * 811 / SCREEN_WIDTH)); Y=$((SCREEN_HEIGHT * 915 / SCREEN_HEIGHT)); return ;;
        2) X=$((SCREEN_WIDTH * 870 / SCREEN_WIDTH)); Y=$((SCREEN_HEIGHT * 915 / SCREEN_HEIGHT)); return ;;
        3) X=$((SCREEN_WIDTH * 923 / SCREEN_WIDTH)); Y=$((SCREEN_HEIGHT * 915 / SCREEN_HEIGHT)); return ;;
        4) X=$((SCREEN_WIDTH * 979 / SCREEN_WIDTH)); Y=$((SCREEN_HEIGHT * 915 / SCREEN_HEIGHT)); return ;;
        5) X=$((SCREEN_WIDTH * 1032 / SCREEN_WIDTH)); Y=$((SCREEN_HEIGHT * 915 / SCREEN_HEIGHT)); return ;;
        6) X=$((SCREEN_WIDTH * 1089 / SCREEN_WIDTH)); Y=$((SCREEN_HEIGHT * 915 / SCREEN_HEIGHT)); return ;;
        7) X=$((SCREEN_WIDTH * 811 / SCREEN_WIDTH)); Y=$((SCREEN_HEIGHT * 1000 / SCREEN_HEIGHT)); return ;;
        8) X=$((SCREEN_WIDTH * 870 / SCREEN_WIDTH)); Y=$((SCREEN_HEIGHT * 1000 / SCREEN_HEIGHT)); return ;;
        9) X=$((SCREEN_WIDTH * 923 / SCREEN_WIDTH)); Y=$((SCREEN_HEIGHT * 1000 / SCREEN_HEIGHT)); return ;;
        10) X=$((SCREEN_WIDTH * 979 / SCREEN_WIDTH)); Y=$((SCREEN_HEIGHT * 1000 / SCREEN_HEIGHT)); return ;;
        11) X=$((SCREEN_WIDTH * 1032 / SCREEN_WIDTH)); Y=$((SCREEN_HEIGHT * 1000 / SCREEN_HEIGHT)); return ;;
        12) X=$((SCREEN_WIDTH * 1089 / SCREEN_WIDTH)); Y=$((SCREEN_HEIGHT * 1000 / SCREEN_HEIGHT)); return ;;
      esac

      MOUSE_X=$((MOUSE_X / 2))
      MOUSE_Y=$((MOUSE_Y / 2))
      X=$((X / 2))
      Y=$((Y / 2))

      echo "Moving mouse to coordinate $X x $Y and double clicking left mouse button" >> "$YDOTOOL_LOG_FILE"

      ydotool mousemove --absolute --xpos 0 --ypos 0
      ydotool mousemove --xpos "$X" --ypos "$Y"
      ydotool click 0xC0 0xC0
      ydotool mousemove --absolute --xpos 0 --ypos 0
      ydotool mousemove --xpos "$MOUSE_X" --ypos "$MOUSE_Y"
    '';
  };
  warcraft-scripts = pkgs.symlinkJoin {
    name = "warcraft-scripts";
    paths = [
      warcraft
      warcraft-mode-start
      warcraft-mode-stop
      warcraft-chat-open
      warcraft-chat-send
      warcraft-chat-close
      warcraft-autocast-hotkey
      warcraft-inventory-hotkey
      warcraft-write-control-group
      warcraft-create-control-group
      warcraft-edit-unit-control-group
      warcraft-select-unit
      inputs.battlenet.packages.${system}.battlenet
      inputs.battlenet.packages.${system}.bonjour
      inputs.battlenet.packages.${system}.w3champions
    ];
  };
in {
  imports = [
    (import ./keys.nix {inherit inputs pkgs lib;})
    (import ./preferences.nix {inherit inputs pkgs lib;})
    (import ./xremap.nix {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      gaming = {
        battlenet = {
          warcraft = {
            enable = lib.mkEnableOption "Enable Warcraft III hotkeys" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.warcraft.enable) {
    environment = {
      systemPackages = [warcraft-scripts];
    };
    home-manager = lib.mkIf (config.modules.home-manager.enable) {
      users = {
        ${name} = {
          home = {
            sessionVariables = {
              WARCRAFT_WINEPREFIX = "$HOME/.local/share/wineprefixes/bnet";
              WARCRAFT_HOME = "$WARCRAFT_WINEPREFIX/drive_c/users/${name}/Documents/Warcraft III";
            };
          };
          xdg = {
            desktopEntries = {
              warcraft = {
                name = "Warcraft III";
                type = "Application";
                categories = ["Game"];
                genericName = "RTS by Blizzard";
                icon = ./assets/warcraft-iii-reforged.svg;
                exec = "${lib.getExe warcraft}";
                terminal = false;
              };
            };
          };
          wayland = {
            windowManager = {
              hyprland = {
                extraConfig = ''
                  bind = CTRL, W, exec, ${lib.getExe warcraft-mode-start}
                  submap = WARCRAFT
                  bind = ALT, W, exec, ${lib.getExe warcraft-mode-stop}
                  bind = SHIFT, Q, exec, ${lib.getExe warcraft-autocast-hotkey} Q
                  bind = SHIFT, W, exec, ${lib.getExe warcraft-autocast-hotkey} W
                  bind = SHIFT, E, exec, ${lib.getExe warcraft-autocast-hotkey} E
                  bind = SHIFT, R, exec, ${lib.getExe warcraft-autocast-hotkey} R
                  bind = SHIFT, A, exec, ${lib.getExe warcraft-autocast-hotkey} A
                  bind = SHIFT, S, exec, ${lib.getExe warcraft-autocast-hotkey} S
                  bind = SHIFT, D, exec, ${lib.getExe warcraft-autocast-hotkey} D
                  bind = SHIFT, F, exec, ${lib.getExe warcraft-autocast-hotkey} F
                  bind = SHIFT, Y, exec, ${lib.getExe warcraft-autocast-hotkey} Y
                  bind = SHIFT, X, exec, ${lib.getExe warcraft-autocast-hotkey} X
                  bind = SHIFT, C, exec, ${lib.getExe warcraft-autocast-hotkey} C
                  bind = SHIFT, V, exec, ${lib.getExe warcraft-autocast-hotkey} V
                  bind = , RETURN, exec, ${lib.getExe warcraft-chat-open}
                  bind = SHIFT, mouse:272, exec, ${lib.getExe warcraft-edit-unit-control-group}
                  bind = , 1, exec, ${lib.getExe warcraft-write-control-group} 1
                  bind = , 2, exec, ${lib.getExe warcraft-write-control-group} 2
                  bind = , 3, exec, ${lib.getExe warcraft-write-control-group} 3
                  bind = , 4, exec, ${lib.getExe warcraft-write-control-group} 4
                  bind = , 5, exec, ${lib.getExe warcraft-write-control-group} 5
                  bind = $mod, 1, exec, ${lib.getExe warcraft-write-control-group} 6
                  bind = $mod, 2, exec, ${lib.getExe warcraft-write-control-group} 7
                  bind = $mod, 3, exec, ${lib.getExe warcraft-write-control-group} 8
                  bind = $mod, 4, exec, ${lib.getExe warcraft-write-control-group} 9
                  bind = $mod, 5, exec, ${lib.getExe warcraft-write-control-group} 0
                  bind = , mouse:276, submap, BTN_EXTRA
                  bind = , mouse:275, submap, BTN_SIDE
                  binde = , XF86AudioRaiseVolume, exec, ${pkgs.wireplumber}/bin/wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+
                  binde = , XF86AudioLowerVolume, exec, ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
                  submap = BTN_EXTRA
                  bind = , 1, exec, ${lib.getExe warcraft-create-control-group} 1
                  bind = , 2, exec, ${lib.getExe warcraft-create-control-group} 2
                  bind = , 3, exec, ${lib.getExe warcraft-create-control-group} 3
                  bind = , 4, exec, ${lib.getExe warcraft-create-control-group} 4
                  bind = , 5, exec, ${lib.getExe warcraft-create-control-group} 5
                  bind = $mod, 1, exec, ${lib.getExe warcraft-create-control-group} 6
                  bind = $mod, 2, exec, ${lib.getExe warcraft-create-control-group} 7
                  bind = $mod, 3, exec, ${lib.getExe warcraft-create-control-group} 8
                  bind = $mod, 4, exec, ${lib.getExe warcraft-create-control-group} 9
                  bind = $mod, 5, exec, ${lib.getExe warcraft-create-control-group} 0
                  bind = , Tab, exec, ${lib.getExe warcraft-inventory-hotkey} 1
                  bind = , Q, exec, ${lib.getExe warcraft-inventory-hotkey} 2
                  bind = , W, exec, ${lib.getExe warcraft-inventory-hotkey} 3
                  bind = , E, exec, ${lib.getExe warcraft-inventory-hotkey} 4
                  bind = , R, exec, ${lib.getExe warcraft-inventory-hotkey} 5
                  bind = , T, exec, ${lib.getExe warcraft-inventory-hotkey} 6
                  bind = , ESCAPE, exec, ${lib.getExe warcraft-select-unit} 1
                  bind = , A, exec, ${lib.getExe warcraft-select-unit} 2
                  bind = , S, exec, ${lib.getExe warcraft-select-unit} 3
                  bind = , D, exec, ${lib.getExe warcraft-select-unit} 4
                  bind = , F, exec, ${lib.getExe warcraft-select-unit} 5
                  bind = , G, exec, ${lib.getExe warcraft-select-unit} 6
                  bind = , ESCAPE, submap, WARCRAFT
                  bind = , A, submap, WARCRAFT
                  bind = , S, submap, WARCRAFT
                  bind = , D, submap, WARCRAFT
                  bind = , F, submap, WARCRAFT
                  bind = , G, submap, WARCRAFT
                  bind = , catchall, submap, WARCRAFT
                  submap = BTN_SIDE
                  bind = , ESCAPE, exec, ${lib.getExe warcraft-select-unit} 7
                  bind = , A, exec, ${lib.getExe warcraft-select-unit} 8
                  bind = , S, exec, ${lib.getExe warcraft-select-unit} 9
                  bind = , D, exec, ${lib.getExe warcraft-select-unit} 10
                  bind = , F, exec, ${lib.getExe warcraft-select-unit} 11
                  bind = , G, exec, ${lib.getExe warcraft-select-unit} 12
                  bind = , ESCAPE, submap, WARCRAFT
                  bind = , A, submap, WARCRAFT
                  bind = , S, submap, WARCRAFT
                  bind = , D, submap, WARCRAFT
                  bind = , F, submap, WARCRAFT
                  bind = , G, submap, WARCRAFT
                  bind = , catchall, submap, WARCRAFT
                  submap = CHAT
                  bind = , RETURN, exec, ${lib.getExe warcraft-chat-send}
                  bind = , ESCAPE, exec, ${lib.getExe warcraft-chat-close}
                  submap = CONTROLGROUP
                  bind = $mod, Q, submap, WARCRAFT
                  bind = $mod SHIFT, Q, submap, reset
                  submap = reset
                '';
              };
            };
          };
        };
      };
    };
  };
}
