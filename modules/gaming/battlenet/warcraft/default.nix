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
      pkgs.systemd
      pkgs.hyprland
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
      pkgs.ydotool
      pkgs.hyprland
    ];
    text = ''
      systemctl --user stop xremap.service
      systemctl --user start xremap-warcraft.service
      hyprctl dispatch submap WARCRAFT
    '';
  };
  warcraft-mode-stop = pkgs.writeShellApplication {
    name = "warcraft-mode-stop";
    runtimeInputs = [
      pkgs.ydotool
      pkgs.hyprland
    ];
    text = ''
      systemctl --user stop xremap-warcraft.service
      systemctl --user start xremap.service
      hyprctl dispatch submap reset
    '';
  };
  warcraft-autocast-hotkey = pkgs.writeShellApplication {
    name = "warcraft-autocast-hotkey";
    runtimeInputs = [
      pkgs.ydotool
      pkgs.hyprland
    ];
    text = ''
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

      MOUSE_POS=$(hyprctl cursorpos)
      MOUSE_X=$(echo "$MOUSE_POS" | cut -d' ' -f1 | cut -d',' -f1)
      MOUSE_Y=$(echo "$MOUSE_POS" | cut -d' ' -f2)

      calculate_coordinates() {
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
      }

      calculate_coordinates

      MOUSE_X=$((MOUSE_X / 2))
      MOUSE_Y=$((MOUSE_Y / 2))
      X=$((X / 2))
      Y=$((Y / 2))

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

      MOUSE_POS=$(hyprctl cursorpos)
      MOUSE_X=$(echo "$MOUSE_POS" | cut -d' ' -f1 | cut -d',' -f1)
      MOUSE_Y=$(echo "$MOUSE_POS" | cut -d' ' -f2)

      calculate_coordinates() {
        case "$HOTKEY" in
          1) X=$((SCREEN_WIDTH * 79 / 128)); Y=$((SCREEN_HEIGHT * 89 / 108)); return ;;
          2) X=$((SCREEN_WIDTH * 21 / 32)); Y=$((SCREEN_HEIGHT * 89 / 108)); return ;;
          3) X=$((SCREEN_WIDTH * 79 / 128)); Y=$((SCREEN_HEIGHT * 8 / 9)); return ;;
          4) X=$((SCREEN_WIDTH * 21 / 32)); Y=$((SCREEN_HEIGHT * 8 / 9)); return ;;
          5) X=$((SCREEN_WIDTH * 79 / 128)); Y=$((SCREEN_HEIGHT * 205 / 216)); return ;;
          6) X=$((SCREEN_WIDTH * 21 / 32)); Y=$((SCREEN_HEIGHT * 205 / 216)); return ;;
        esac
      }

      calculate_coordinates

      MOUSE_X=$((MOUSE_X / 2))
      MOUSE_Y=$((MOUSE_Y / 2))
      X=$((X / 2))
      Y=$((Y / 2))

      ydotool mousemove --absolute --xpos 0 --ypos 0
      ydotool mousemove --xpos "$X" --ypos "$Y"
      ydotool click 0xC0
      ydotool mousemove --absolute --xpos 0 --ypos 0
      ydotool mousemove --xpos "$MOUSE_X" --ypos "$MOUSE_Y"
    '';
  };
  warcraft-chat-open = pkgs.writeShellApplication {
    name = "warcraft-chat-open";
    runtimeInputs = [
      pkgs.ydotool
      pkgs.hyprland
      pkgs.systemd
    ];
    text = ''
      systemctl --user stop xremap-warcraft.service
      systemctl --user start xremap.service
      ydotool key 96:1 96:0 # Press Numpad_Enter
      hyprctl dispatch submap CHAT
    '';
  };
  warcraft-chat-send = pkgs.writeShellApplication {
    name = "warcraft-chat-send";
    runtimeInputs = [
      pkgs.ydotool
      pkgs.hyprland
    ];
    text = ''
      systemctl --user stop xremap.service
      systemctl --user start xremap-warcraft.service
      ydotool key 96:1 96:0 # Press Numpad_Enter
      hyprctl dispatch submap WARCRAFT
    '';
  };
  warcraft-chat-close = pkgs.writeShellApplication {
    name = "warcraft-chat-close";
    runtimeInputs = [
      pkgs.ydotool
      pkgs.hyprland
    ];
    text = ''
      systemctl --user stop xremap.service
      systemctl --user start xremap-warcraft.service
      ydotool key 58:1 58:0 # Press caps lock which is actually escape
      ydotool key 1:1 1:0 # Press escape again to be sure
      hyprctl dispatch submap WARCRAFT
    '';
  };
  warcraft-create-control-group = pkgs.writeShellApplication {
    name = "warcraft-create-control-group";
    runtimeInputs = [
      pkgs.ydotool
      pkgs.hyprland
    ];
    excludeShellChecks = ["SC2046" "SC2086"];
    text = ''
      YDOTOOL_LOG_FILE="$HOME/.local/share/wineprefixes/bnet/drive_c/users/${name}/Documents/Warcraft III/ydotool_log"

      hyprctl dispatch submap CONTROLGROUP &

      SELECTED_CONTROL_GROUP="$1"
      CONTROL_GROUP_FILE="$HOME/.local/share/wineprefixes/bnet/drive_c/users/${name}/Documents/Warcraft III/control_group"
      CONTROL_GROUP_KEYCODE_FILE="$HOME/.local/share/wineprefixes/bnet/drive_c/users/${name}/Documents/Warcraft III/control_group_keycode"

      echo "Creating control group $SELECTED_CONTROL_GROUP" >> "$YDOTOOL_LOG_FILE"

      echo "$SELECTED_CONTROL_GROUP" > "$CONTROL_GROUP_FILE"

      get_control_group_keycode() {
        case "$SELECTED_CONTROL_GROUP" in
          1) CONTROL_GROUP_KEYCODE=2; return ;;
          2) CONTROL_GROUP_KEYCODE=3; return ;;
          3) CONTROL_GROUP_KEYCODE=4; return ;;
          4) CONTROL_GROUP_KEYCODE=5; return ;;
          5) CONTROL_GROUP_KEYCODE=6; return ;;
          6) CONTROL_GROUP_KEYCODE=7; return ;;
          7) CONTROL_GROUP_KEYCODE=8; return ;;
          8) CONTROL_GROUP_KEYCODE=9; return ;;
          9) CONTROL_GROUP_KEYCODE=10; return ;;
          0) CONTROL_GROUP_KEYCODE=11; return ;;
        esac
      }

      get_control_group_keycode

      echo "$CONTROL_GROUP_KEYCODE" > "$CONTROL_GROUP_KEYCODE_FILE"

      echo "Pressing $CONTROL_GROUP_KEYCODE keycode with space modifiers" >> "$YDOTOOL_LOG_FILE"

      sleep 0.08

      ydotool key 57:1 $CONTROL_GROUP_KEYCODE:1 $CONTROL_GROUP_KEYCODE:0 57:0

      hyprctl dispatch submap WARCRAFT
    '';
  };
  warcraft-select-control-group = pkgs.writeShellApplication {
    name = "warcraft-select-control-group";
    runtimeInputs = [
      pkgs.ydotool
      pkgs.hyprland
    ];
    excludeShellChecks = ["SC2046" "SC2086"];
    text = ''
      SELECTED_CONTROL_GROUP="$1"
      CONTROL_GROUP_FILE="$HOME/.local/share/wineprefixes/bnet/drive_c/users/${name}/Documents/Warcraft III/control_group"
      YDOTOOL_LOG_FILE="$HOME/.local/share/wineprefixes/bnet/drive_c/users/${name}/Documents/Warcraft III/ydotool_log"

      hyprctl dispatch submap CONTROLGROUP &

      echo "Selecting control group $SELECTED_CONTROL_GROUP" >> "$YDOTOOL_LOG_FILE"
      echo "$SELECTED_CONTROL_GROUP" > "$CONTROL_GROUP_FILE"

      echo "Typing $SELECTED_CONTROL_GROUP" >> "$YDOTOOL_LOG_FILE"

      sleep 0.08

      ydotool type "$SELECTED_CONTROL_GROUP"

      hyprctl dispatch submap WARCRAFT
    '';
  };
  warcraft-remove-unit-control-group = pkgs.writeShellApplication {
    name = "warcraft-remove-unit-control-group";
    runtimeInputs = [
      pkgs.ydotool
      pkgs.hyprland
    ];
    excludeShellChecks = ["SC2046" "SC2086"];
    text = ''
      YDOTOOL_LOG_FILE="$HOME/.local/share/wineprefixes/bnet/drive_c/users/${name}/Documents/Warcraft III/ydotool_log"

      hyprctl dispatch submap CONTROLGROUP &

      echo "Removing unit from control group" >> "$YDOTOOL_LOG_FILE"

      echo "Pressing left shift" >> "$YDOTOOL_LOG_FILE"
      ydotool key 42:1
      echo "Clicking left mouse button" >> "$YDOTOOL_LOG_FILE"
      ydotool click 0xC0
      echo "Releasing left shift" >> "$YDOTOOL_LOG_FILE"
      ydotool key 42:0

      CONTROL_GROUP_KEYCODE_FILE="$HOME/.local/share/wineprefixes/bnet/drive_c/users/${name}/Documents/Warcraft III/control_group_keycode"
      CONTROL_GROUP_KEYCODE="$(cat "$CONTROL_GROUP_KEYCODE_FILE")"

      echo "Pressing $CONTROL_GROUP_KEYCODE keycode with space modifier" >> "$YDOTOOL_LOG_FILE"

      sleep 0.08

      ydotool key 57:1 $CONTROL_GROUP_KEYCODE:1 $CONTROL_GROUP_KEYCODE:0 57:0

      hyprctl dispatch submap WARCRAFT
    '';
  };
  warcraft-scripts = pkgs.symlinkJoin {
    name = "warcraft-scripts";
    paths = [
      warcraft
      warcraft-mode-start
      warcraft-mode-stop
      warcraft-autocast-hotkey
      warcraft-inventory-hotkey
      warcraft-chat-open
      warcraft-chat-send
      warcraft-chat-close
      warcraft-create-control-group
      warcraft-select-control-group
      warcraft-remove-unit-control-group
    ];
  };
in {
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
    systemd = {
      user = {
        services = {
          xremap-warcraft = {
            description = "xremap-warcraft user service";
            path = [config.services.xremap.package];
            serviceConfig = lib.mkMerge [
              {
                KeyringMode = "private";
                SystemCallArchitectures = ["native"];
                RestrictRealtime = true;
                ProtectSystem = true;
                SystemCallFilter = map (x: "~@${x}") [
                  "clock"
                  "debug"
                  "module"
                  "reboot"
                  "swap"
                  "cpu-emulation"
                  "obsolete"
                ];
                LockPersonality = true;
                UMask = "077";
                RestrictAddressFamilies = "AF_UNIX";
                ExecStart = let
                  mkExecStart = configFile: let
                    cfg = config.services.xremap;
                    mkDeviceString = x: "--device '${x}'";
                  in
                    builtins.concatStringsSep " " (
                      lib.flatten (
                        lib.lists.singleton "${lib.getExe cfg.package}"
                        ++ (
                          /*
                          Logic to handle --device parameter.

                          Originally only "deviceName" (singular) was an option. Upstream implemented multiple devices, e.g.:
                          https://github.com/xremap/xremap/issues/44

                          Option "deviceNames" (plural) is implemented to allow passing a list of devices to remap.

                          Legacy parameter wins by default to prevent surprises, but emits a warning.
                          */
                          if cfg.deviceName != ""
                          then
                            lib.pipe cfg.deviceName [
                              mkDeviceString
                              lib.singleton
                              (lib.showWarnings [
                                "'deviceName' option is deprecated in favor of 'deviceNames'. Current value will continue working but please replace it with 'deviceNames'."
                              ])
                            ]
                          else if cfg.deviceNames != null
                          then map mkDeviceString cfg.deviceNames
                          else []
                        )
                        ++ lib.optional cfg.watch "--watch"
                        ++ lib.optional cfg.mouse "--mouse"
                        ++ cfg.extraArgs
                        ++ lib.lists.singleton configFile
                      )
                    );
                  configFile = pkgs.writeTextFile {
                    name = "xremap-warcraft-config.yml";
                    text = ''
                      modmap:
                        - name: Swap Space & Ctrl
                          remap:
                            LeftCtrl: Space
                            Space: LeftCtrl

                        - name: "Better CapsLock"
                          remap:
                            CapsLock:
                              held: SUPER_L
                              alone: ESC
                              alone_timeout_millis: 500
                    '';
                  };
                in
                  mkExecStart configFile;
              }
              (lib.optionalAttrs config.services.xremap.debug {Environment = ["RUST_LOG=debug"];})
            ];
          };
        };
      };
    };
    home-manager = lib.mkIf (config.modules.home-manager.enable) {
      users = {
        ${name} = {
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
                  bind = Alt_L, W, exec, ${lib.getExe warcraft-mode-stop}
                  bind = , RETURN, exec, ${lib.getExe warcraft-chat-open}
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
                  bind = CTRL, Q, exec, ${lib.getExe warcraft-inventory-hotkey} 1
                  bind = CTRL, W, exec, ${lib.getExe warcraft-inventory-hotkey} 2
                  bind = CTRL, A, exec, ${lib.getExe warcraft-inventory-hotkey} 3
                  bind = CTRL, S, exec, ${lib.getExe warcraft-inventory-hotkey} 4
                  bind = CTRL, Y, exec, ${lib.getExe warcraft-inventory-hotkey} 5
                  bind = CTRL, X, exec, ${lib.getExe warcraft-inventory-hotkey} 6
                  bind = CTRL, 1, exec, ${lib.getExe warcraft-create-control-group} 1
                  bind = CTRL, 2, exec, ${lib.getExe warcraft-create-control-group} 2
                  bind = CTRL, 3, exec, ${lib.getExe warcraft-create-control-group} 3
                  bind = CTRL, 4, exec, ${lib.getExe warcraft-create-control-group} 4
                  bind = CTRL, 5, exec, ${lib.getExe warcraft-create-control-group} 5
                  bind = CTRL, 6, exec, ${lib.getExe warcraft-create-control-group} 6
                  bind = CTRL, 7, exec, ${lib.getExe warcraft-create-control-group} 7
                  bind = CTRL, 8, exec, ${lib.getExe warcraft-create-control-group} 8
                  bind = CTRL, 9, exec, ${lib.getExe warcraft-create-control-group} 9
                  bind = CTRL, 0, exec, ${lib.getExe warcraft-create-control-group} 0
                  bind = , 1, exec, ${lib.getExe warcraft-select-control-group} 1
                  bind = , 2, exec, ${lib.getExe warcraft-select-control-group} 2
                  bind = , 3, exec, ${lib.getExe warcraft-select-control-group} 3
                  bind = , 4, exec, ${lib.getExe warcraft-select-control-group} 4
                  bind = , 5, exec, ${lib.getExe warcraft-select-control-group} 5
                  bind = , 6, exec, ${lib.getExe warcraft-select-control-group} 6
                  bind = , 7, exec, ${lib.getExe warcraft-select-control-group} 7
                  bind = , 8, exec, ${lib.getExe warcraft-select-control-group} 8
                  bind = , 9, exec, ${lib.getExe warcraft-select-control-group} 9
                  bind = , 0, exec, ${lib.getExe warcraft-select-control-group} 0
                  bind = SHIFT, mouse:272, exec, ${lib.getExe warcraft-remove-unit-control-group}
                  bindr = CAPS, Caps_Lock, exec, true
                  submap = CONTROLGROUP
                  bind = $mod, Q, submap, WARCRAFT
                  bind = $mod SHIFT, Q, submap, reset
                  submap = CHAT
                  bind = , RETURN, exec, ${lib.getExe warcraft-chat-send}
                  bind = , ESCAPE, exec, ${lib.getExe warcraft-chat-close}
                  submap = reset
                '';
              };
            };
          };
          home = {
            file = {
              ".local/share/wineprefixes/bnet/drive_c/users/${name}/Documents/Warcraft III/War3Preferences.txt" = {
                text = ''
                  [Commandbar Hotkeys 00]
                  HeroOnly=0
                  Hotkey=81
                  MetaKeyState=0
                  QuickCast=0

                  [Commandbar Hotkeys 01]
                  HeroOnly=0
                  Hotkey=87
                  MetaKeyState=0
                  QuickCast=0

                  [Commandbar Hotkeys 02]
                  HeroOnly=0
                  Hotkey=69
                  MetaKeyState=0
                  QuickCast=0

                  [Commandbar Hotkeys 03]
                  HeroOnly=0
                  Hotkey=82
                  MetaKeyState=0
                  QuickCast=0

                  [Commandbar Hotkeys 10]
                  HeroOnly=0
                  Hotkey=65
                  MetaKeyState=0
                  QuickCast=0

                  [Commandbar Hotkeys 11]
                  HeroOnly=0
                  Hotkey=83
                  MetaKeyState=0
                  QuickCast=0

                  [Commandbar Hotkeys 12]
                  HeroOnly=0
                  Hotkey=68
                  MetaKeyState=0
                  QuickCast=0

                  [Commandbar Hotkeys 13]
                  HeroOnly=0
                  Hotkey=70
                  MetaKeyState=0
                  QuickCast=0

                  [Commandbar Hotkeys 20]
                  HeroOnly=0
                  Hotkey=90
                  MetaKeyState=0
                  QuickCast=0

                  [Commandbar Hotkeys 21]
                  HeroOnly=0
                  Hotkey=88
                  MetaKeyState=0
                  QuickCast=0

                  [Commandbar Hotkeys 22]
                  HeroOnly=0
                  Hotkey=67
                  MetaKeyState=0
                  QuickCast=0

                  [Commandbar Hotkeys 23]
                  HeroOnly=0
                  Hotkey=86
                  MetaKeyState=0
                  QuickCast=0

                  [Custom Hotkeys 0]
                  FromHotkey=0
                  FromKeyEnabled=0
                  FromMetaKeyState=0
                  HeroOnly=0
                  ToHotkey=0
                  ToKeyEnabled=0
                  ToMetaKeyState=0

                  [Custom Hotkeys 1]
                  FromHotkey=0
                  FromKeyEnabled=0
                  FromMetaKeyState=0
                  HeroOnly=0
                  ToHotkey=0
                  ToKeyEnabled=0
                  ToMetaKeyState=0

                  [Custom Hotkeys 2]
                  FromHotkey=0
                  FromKeyEnabled=0
                  FromMetaKeyState=0
                  HeroOnly=0
                  ToHotkey=0
                  ToKeyEnabled=0
                  ToMetaKeyState=0

                  [Custom Hotkeys 3]
                  FromHotkey=0
                  FromKeyEnabled=0
                  FromMetaKeyState=0
                  HeroOnly=0
                  ToHotkey=0
                  ToKeyEnabled=0
                  ToMetaKeyState=0

                  [Custom Hotkeys 4]
                  FromHotkey=0
                  FromKeyEnabled=0
                  FromMetaKeyState=0
                  HeroOnly=0
                  ToHotkey=0
                  ToKeyEnabled=0
                  ToMetaKeyState=0

                  [Custom Hotkeys 5]
                  FromHotkey=0
                  FromKeyEnabled=0
                  FromMetaKeyState=0
                  HeroOnly=0
                  ToHotkey=0
                  ToKeyEnabled=0
                  ToMetaKeyState=0

                  [Custom Hotkeys 6]
                  FromHotkey=0
                  FromKeyEnabled=0
                  FromMetaKeyState=0
                  HeroOnly=0
                  ToHotkey=0
                  ToKeyEnabled=0
                  ToMetaKeyState=0

                  [Custom Hotkeys 7]
                  FromHotkey=0
                  FromKeyEnabled=0
                  FromMetaKeyState=0
                  HeroOnly=0
                  ToHotkey=0
                  ToKeyEnabled=0
                  ToMetaKeyState=0

                  [Gameplay]
                  allyFilter=1
                  ammmaphashes=
                  ammmapprefs=
                  ammrace=32
                  ammstyles=
                  ammtype=0
                  autosaveReplay=1
                  bgMenuMovie=2
                  cinePortraits=1
                  classicCursor=0
                  coloredhealthbars=1
                  commandbuttonhotkey=1
                  creepFilter=1
                  customfilter=0
                  custommask=0
                  defaultZoom=3000
                  denyIcon=1
                  displayapm=1
                  displayfps=1
                  displayping=1
                  enabledAdvancedObserverUi=false
                  enabledEnhancedZoom=1
                  enabledGameInfoMessages=1
                  enabledGlobalChat=1
                  enabledObserverChat=true
                  enabledOpponentChat=1
                  enabledTeamChat=true
                  formations=0
                  formationtoggle=1
                  gamespeed=2
                  goldmineUnitCounter=1
                  healthbars=1
                  herobar=1
                  heroframes=1
                  herolevel=1
                  hudscale=100
                  hudsidepanels=1
                  maxZoom=3000
                  multiboardon=1
                  netgameport=6112
                  numericCooldown=1
                  occlusion=0
                  peonDoubleTapFocus=1
                  profanity=0
                  schedrace=32
                  showtimeelapsed=1
                  subgrouporder=1
                  teen=0
                  terrainFilter=1
                  tooltips=1
                  useSkins=1

                  [Input]
                  confinemousecursor=1
                  customkeys=1
                  keyscroll=50
                  mousescroll=50
                  mousescrolldisable=0
                  reducemouselag=1

                  [Inventory Hotkeys 0]
                  HeroOnly=0
                  Hotkey=84
                  MetaKeyState=0
                  QuickCast=0

                  [Inventory Hotkeys 1]
                  HeroOnly=0
                  Hotkey=89
                  MetaKeyState=0
                  QuickCast=0

                  [Inventory Hotkeys 2]
                  HeroOnly=0
                  Hotkey=71
                  MetaKeyState=0
                  QuickCast=0

                  [Inventory Hotkeys 3]
                  HeroOnly=0
                  Hotkey=72
                  MetaKeyState=0
                  QuickCast=0

                  [Inventory Hotkeys 4]
                  HeroOnly=0
                  Hotkey=66
                  MetaKeyState=0
                  QuickCast=0

                  [Inventory Hotkeys 5]
                  HeroOnly=0
                  Hotkey=78
                  MetaKeyState=0
                  QuickCast=0

                  [Map]
                  battlenet_V0=
                  battlenet_V1=
                  lan_V0=
                  lan_V1=
                  skirmish_V0=
                  skirmish_V1=

                  [Misc]
                  bnetGateway=
                  chatsupport=0
                  clickedad=0
                  clickedclan=0
                  clickedladder=0
                  clickedtourn=0
                  hd=0
                  lastseasonseen=0
                  legacylinkreminder=1
                  offlineavatar=p068
                  regioncomplianceaccepted=0
                  seenintromovie=1
                  settingsversion=3
                  versusUnrankedPreferred=0

                  [Mouse Mid Button Down]
                  HeroOnly=0
                  ToHotkey=0
                  ToKeyEnabled=0
                  ToMetaKeyState=0

                  [Mouse Wheel Down]
                  HeroOnly=0
                  ToHotkey=0
                  ToKeyEnabled=0
                  ToMetaKeyState=0

                  [Mouse Wheel Up]
                  HeroOnly=0
                  ToHotkey=0
                  ToKeyEnabled=0
                  ToMetaKeyState=0

                  [Reforged]
                  Buildings=1
                  Environment=1
                  EnvOld=0
                  Heroes=1
                  Icons=1
                  Textures=1
                  Units=1
                  Vfx=1

                  [Sound]
                  ambient=1
                  assetmode=0
                  classicsound=1
                  donotusewaveout=0
                  environmental=1
                  movement=1
                  music=1
                  musicoverride=
                  musicvolume=30
                  nosoundwarn=1
                  outputsounddev=0
                  outputspeakermode=-1
                  positional=1
                  sfx=1
                  sfxvolume=50
                  subtitles=1
                  unit=1
                  windowfocus=1

                  [String]
                  gamemodePreferred=1v1
                  userbnet=
                  userlocal=

                  [Video]
                  adapter=0
                  antialiasing=1
                  backgroundmaxfps=10
                  colordepth=32
                  foliagequality=3
                  gamma=30
                  lightingquality=2
                  maxfps=300
                  particles=2
                  previouswindowmode=0
                  refreshrate=240
                  resetdefaults=0
                  resheight=1080
                  reswidth=1920
                  shadowquality=3
                  spellfilter=2
                  texquality=2
                  vsync=0
                  windowheight=810
                  windowmode=2
                  windowwidth=1440
                  windowx=240
                  windowy=135
                '';
              };
              ".local/share/wineprefixes/bnet/drive_c/users/${name}/Documents/Warcraft III/CustomKeyBindings/CustomKeys.txt" = {
                text = ''
                  /////////////////////////////////////////////////////
                  // Customized for Lefthanded Keyboard Alignment (QWEASY)
                  // Simply place this Customkeys.txt file into your WC3
                  // folder usually under Documents or Program Files then
                  // in the game options Enable Custom Keyboard Shortcuts
                  // This Version is specific for German Keyboards (Z=Y)
                  ///////////////////////////////////////////////////////

                  /////////////////////////////////////////////////////////
                  // This Custom Keys setup aligns all races units, heroes,
                  // upgrades, buildings and abilities, to the left side of
                  // any standard keyboard, and matches the in-game command
                  // menu. All unit spells and abilities have been moved to
                  // the QWERASY position for most sufficient Hotkey access
                  //    Move is now Y   Attack and Stop are still A and S
                  //  Works great combined with Warkey for Inventory items!
                  ///////////////////////////////////////////////////////////

                  [cmdcancel]
                  Tip=(|cffffcc00ESC|r) Cancel
                  Hotkey=512
                  Buttonpos=3,2

                  [cmdcancelbuild]
                  Tip=(|cffffcc00ESC|r) Cancel
                  Hotkey=512
                  Buttonpos=3,2

                  [cmdrally]
                  Tip=(|cffffcc00F|r) Set Rally Point
                  Hotkey=F
                  [ARal]
                  Buttonpos=3,1

                  [cmdattack]
                  Tip=(|cffffcc00A|r) Attack
                  Hotkey=A
                  Buttonpos=0,1

                  [cmdstop]
                  Tip=(|cffffcc00S|r) Stop
                  Hotkey=S
                  Buttonpos=1,1

                  [cmdmove]
                  Tip=(|cffffcc00Y|r) Move
                  Hotkey=Y
                  Buttonpos=0,2

                  [cmdholdpos]
                  Tip=(|cffffcc00X|r) Hold Position
                  Hotkey=X
                  Buttonpos=1,2

                  [cmdpatrol]
                  Tip=(|cffffcc00C|r) Patrol
                  Hotkey=C
                  Buttonpos=2,2

                  [cmdattackground]
                  Tip=(|cffffcc00Q|r) Attack Ground
                  Hotkey=Q
                  Buttonpos=0,0

                  [asal]
                  Tip=Pillage
                  Buttonpos=1,0

                  [ashm]
                  Tip=(|cffffcc00D|r) Hide
                  Hotkey=D
                  Buttonpos=2,1

                  [ahid]
                  Tip=(|cffffcc00D|r) Hide
                  Hotkey=D
                  Buttonpos=2,1

                  [ahar]
                  Tip=(|cffffcc00F|r) Gather
                  UnTip=(|cffffcc00F|r) Return Resources
                  Hotkey=F
                  Unhotkey=F
                  Buttonpos=3,1
                  Unbuttonpos=3,1

                  [cmdselectskill]
                  Tip=(|cffffcc00F|r) Set Hero Ability
                  Hotkey=F
                  Buttonpos=3,1

                  [slo3]
                  Tip=(|cffffcc00Q|r) Load
                  Hotkey=Q
                  Buttonpos=0,0

                  [sdro]
                  Tip=(|cffffcc00W|r) Unload All
                  Hotkey=W
                  Buttonpos=1,0

                  [anei]
                  Tip=(|cffffcc00V|r) Select User
                  Hotkey=V
                  Buttonpos=3,2

                  [plcl]
                  Tip=(|cffffcc00W|r) Purchase Lesser Clarity Potion
                  Hotkey=W
                  Buttonpos=1,0

                  [dust]
                  Tip=(|cffffcc00E|r) Purchase Dust of Appearance
                  Hotkey=E
                  Buttonpos=2,0

                  [phea]
                  Tip=(|cffffcc00A|r) Purchase Potion of Healing
                  Hotkey=A
                  Buttonpos=0,1

                  [pman]
                  Tip=(|cffffcc00S|r) Purchase Potion of Mana
                  Hotkey=S
                  Buttonpos=1,1

                  [stwp]
                  Tip=(|cffffcc00D|r) Purchase Scroll of Town Portal
                  Hotkey=D
                  Buttonpos=2,1

                  [shea]
                  Tip=(|cffffcc00X|r) Purchase Scroll of Healing
                  Hotkey=X
                  Buttonpos=1,2

                  [adsm]
                  Tip=(|cffffcc00E|r) Dispel Magic
                  Hotkey=E
                  Buttonpos=1,0

                  [acrk]
                  Tip=Resistant Skin
                  Buttonpos=1,0

                  [acsk]
                  Tip=Resistant Skin
                  Buttonpos=3,1

                  [amim]
                  Tip=Spell Immunity
                  Buttonpos=2,0

                  [acmi]
                  Tip=Spell Immunity
                  Buttonpos=2,0

                  [acd2]
                  Tip=(|cffffcc00W|r) Abolish Magic
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,0

                  [hpea]
                  Tip=(|cffffcc00Q|r) Train Peasant
                  Hotkey=Q
                  Buttonpos=0,0

                  [rhpm]
                  Tip=(|cffffcc00X|r) Research Backpack
                  Hotkey=X
                  Buttonpos=1,2

                  [hkee]
                  Tip=(|cffffcc00Y|r) Upgrade to Keep
                  Hotkey=Y
                  Buttonpos=0,2

                  [amic]
                  Tip=(|cffffcc00E|r) Call to Arms
                  UnTip=(|cffffcc00W|r) Back to Work
                  Hotkey=E
                  Unhotkey=W
                  Buttonpos=2,0
                  Unbuttonpos=1,0

                  [hcas]
                  Tip=(|cffffcc00Y|r) Upgrade to Castle
                  Hotkey=Y
                  Buttonpos=0,2

                  [Hamg]
                  Tip=(|cffffcc00Y|r) Summon Archmage
                  Revivetip=(|cffffcc00Y|r) Revive Archmage
                  Awakentip=(|cffffcc00Y|r) Awaken Archmage
                  Hotkey=Y
                  Buttonpos=0,2

                  [Hmkg]
                  Tip=(|cffffcc00X|r) Summon Mountain King
                  Revivetip=(|cffffcc00X|r) Revive Mountain King
                  Awakentip=(|cffffcc00X|r) Awaken Mountain King
                  Hotkey=X
                  Buttonpos=1,2

                  [Hpal]
                  Tip=(|cffffcc00C|r) Summon Paladin
                  Revivetip=(|cffffcc00C|r) Revive Paladin
                  Awakentip=(|cffffcc00C|r) Awaken Paladin
                  Hotkey=C
                  Buttonpos=2,2

                  [Hblm]
                  Tip=(|cffffcc00A|r) Summon Blood Mage
                  Revivetip=(|cffffcc00A|r) Revive Blood Mage
                  Awakentip=(|cffffcc00A|r) Awaken Blood Mage
                  Hotkey=A
                  Buttonpos=0,1

                  [hfoo]
                  Tip=(|cffffcc00Q|r) Train Footman
                  Hotkey=Q
                  Buttonpos=0,0

                  [hrif]
                  Tip=(|cffffcc00W|r) Train Rifleman
                  Hotkey=W
                  Buttonpos=1,0

                  [hkni]
                  Tip=(|cffffcc00E|r) Train Knight
                  Hotkey=E
                  Buttonpos=2,0

                  [rhde]
                  Tip=(|cffffcc00Y|r) Research Defend
                  Hotkey=Y
                  Buttonpos=0,2

                  [rhri]
                  Tip=(|cffffcc00X|r) Upgrade to Long Rifles
                  Hotkey=X
                  Buttonpos=1,2

                  [rhan]
                  Tip=(|cffffcc00C|r) Research Animal War Training
                  Hotkey=C
                  Buttonpos=2,2

                  [hgyr]
                  Tip=(|cffffcc00Q|r) Train Flying Machine
                  Hotkey=Q
                  Buttonpos=0,0

                  [hmtm]
                  Tip=(|cffffcc00W|r) Train Mortar Team
                  Hotkey=W
                  Buttonpos=1,0

                  [hmtt]
                  Tip=(|cffffcc00E|r) Train Siege Engine,(|cffffcc00E|r) Train Siege Barrage
                  Hotkey=E,E
                  Buttonpos=2,0

                  [hrtt]
                  Tip=(|cffffcc00E|r) Train Siege Engine
                  Hotkey=E
                  Buttonpos=2,0

                  [rhfc]
                  Tip=(|cffffcc00A|r) Research Flak Cannons
                  Hotkey=A
                  Buttonpos=0,1

                  [rhfs]
                  Tip=(|cffffcc00X|r) Research Fragmentation Shards
                  Hotkey=X
                  Buttonpos=1,2

                  [rhgb]
                  Tip=(|cffffcc00Y|r) Research Flying Machine Bombs
                  Hotkey=Y
                  Buttonpos=0,2

                  [rhfl]
                  Tip=(|cffffcc00S|r) Research Flare
                  Hotkey=S
                  Buttonpos=1,1

                  [rhrt]
                  Tip=(|cffffcc00C|r) Research Barrage
                  Hotkey=C
                  Buttonpos=2,2

                  [hsor]
                  Tip=(|cffffcc00Q|r) Train Sorceress
                  Hotkey=Q
                  Buttonpos=0,0

                  [hmpr]
                  Tip=(|cffffcc00W|r) Train Priest
                  Hotkey=W
                  Buttonpos=1,0

                  [hspt]
                  Tip=(|cffffcc00E|r) Train Spell Breaker
                  Hotkey=E
                  Buttonpos=2,0

                  [rhss]
                  Tip=(|cffffcc00C|r) Research Control Magic
                  Hotkey=C
                  Buttonpos=2,2

                  [rhst]
                  Tip=(|cffffcc00Y|r) Sorceress Adept Training,(|cffffcc00Y|r) Sorceress Master Training
                  Hotkey=Y,Y
                  Buttonpos=0,2

                  [rhpt]
                  Tip=(|cffffcc00X|r) Priest Adept Training,(|cffffcc00X|r) Priest Master Training
                  Hotkey=X,X
                  Buttonpos=1,2

                  [rhse]
                  Tip=(|cffffcc00R|r) Research Magic Sentry
                  Hotkey=R
                  Buttonpos=3,0

                  [hdhw]
                  Tip=(|cffffcc00Q|r) Train Dragon Hawk
                  Hotkey=Q
                  Buttonpos=0,0

                  [hgry]
                  Tip=(|cffffcc00W|r) Train Gryphon Rider
                  Hotkey=W
                  Buttonpos=1,0

                  [rhcd]
                  Tip=(|cffffcc00Y|r) Research Cloud
                  Hotkey=Y
                  Buttonpos=0,2

                  [rhhb]
                  Tip=(|cffffcc00X|r) Research Storm Hammers
                  Hotkey=X
                  Buttonpos=1,2

                  [rhlh]
                  Tip=(|cffffcc00Q|r) Improved Lumber Harvesting,(|cffffcc00Q|r) Advanced Lumber Harvesting
                  Hotkey=Q,Q
                  Buttonpos=0,0

                  [rhac]
                  Tip=(|cffffcc00W|r) Upgrade to Improved Masonry,(|cffffcc00W|r) Upgrade to Advanced Masonry,(|cffffcc00W|r) Upgrade to Imbued Masonry
                  Hotkey=W,W,W
                  Buttonpos=1,0

                  [rhme]
                  Tip=(|cffffcc00Q|r) Upgrade to Iron Forged Swords,(|cffffcc00Q|r) Upgrade to Steel Forged Swords,(|cffffcc00Q|r) Upgrade to Mithril Forged Swords
                  Hotkey=Q,Q,Q
                  Buttonpos=0,0

                  [rhra]
                  Tip=(|cffffcc00W|r) Upgrade to Black Gunpowder,(|cffffcc00W|r) Upgrade Refined Gunpowder,(|cffffcc00W|r) Upgrade to Imbued Gunpowder
                  Hotkey=W,W,W
                  Buttonpos=1,0

                  [rhar]
                  Tip=(|cffffcc00A|r) Upgrade to Iron Plating,(|cffffcc00A|r) Upgrade to Steel Plating,(|cffffcc00A|r) Upgrade to Mithril Plating
                  Hotkey=A,A,A
                  Buttonpos=0,1

                  [rhla]
                  Tip=(|cffffcc00S|r) Upgrade to Studded Leather Armor,(|cffffcc00S|r) Upgrade to Reinforced Leather Armor,(|cffffcc00S|r) Upgrade to Dragonhide Armor
                  Hotkey=S,S,S
                  Buttonpos=1,1

                  [hgtw]
                  Tip=(|cffffcc00W|r) Upgrade to Guard Tower
                  Hotkey=W
                  Buttonpos=1,0

                  [hctw]
                  Tip=(|cffffcc00E|r) Upgrade to Cannon Tower
                  Hotkey=E
                  Buttonpos=2,0

                  [hatw]
                  Tip=(|cffffcc00Q|r) Upgrade to Arcane Tower
                  Hotkey=Q
                  Buttonpos=0,0

                  [ahta]
                  Tip=(|cffffcc00Q|r) Reveal
                  Hotkey=Q
                  Buttonpos=0,0

                  [adts]
                  Tip=Magic Sentry
                  Buttonpos=3,0

                  [afbt]
                  Tip=Feedback
                  Buttonpos=1,0

                  [sreg]
                  Tip=(|cffffcc00Q|r) Purchase Scroll of Regeneration
                  Hotkey=Q
                  Buttonpos=0,0

                  [mcri]
                  Tip=(|cffffcc00E|r) Purchase Mechanical Critter
                  Hotkey=E
                  Buttonpos=2,0

                  [tsct]
                  Tip=(|cffffcc00F|r) Purchase Ivory Tower
                  Hotkey=F
                  Buttonpos=3,1

                  [ofir]
                  Tip=(|cffffcc00Y|r) Purchase Orb of Fire
                  Hotkey=Y
                  Buttonpos=0,2

                  [ofr2]
                  Tip=(|cffffcc00Y|r) Purchase Orb of Fire
                  Hotkey=Y
                  Buttonpos=0,2

                  [ritd]
                  Tip=(|cffffcc00R|r) Purchase Ritual Dagger
                  Hotkey=R
                  Buttonpos=3,0

                  [AIhm]
                  Tip=(|cffffcc00D|r) Hide
                  Hotkey=D
                  Buttonpos=2,1

                  [Ahsb]
                  Tip=(|cffffcc00Q|r) Sundering Blades
                  Hotkey=Q
                  Buttonpos=0,0

                  [Rhsb]
                  Tip=(|cffffcc00D|r) Research Sundering Blades
                  Hotkey=D
                  Buttonpos=2,1

                  [ssan]
                  Tip=(|cffffcc00X|r) Purchase Staff of Sanctuary
                  Hotkey=X
                  Buttonpos=1,2

                  [cmdbuildhuman]
                  Tip=(|cffffcc00Q|r) Build Structure
                  Hotkey=Q
                  [AHbu]
                  Buttonpos=0,0

                  [ahrp]
                  Tip=(|cffffcc00R|r) Repair
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=R
                  Buttonpos=3,0
                  Unbuttonpos=3,0

                  [amil]
                  Tip=(|cffffcc00E|r) Call to Arms
                  UnTip=(|cffffcc00W|r) Return to Work
                  Hotkey=E
                  Unhotkey=W
                  Buttonpos=2,0
                  Unbuttonpos=1,0

                  [htow]
                  Tip=(|cffffcc00Y|r) Build Town Hall
                  Hotkey=Y
                  Buttonpos=0,2

                  [hbar]
                  Tip=(|cffffcc00W|r) Build Barracks
                  Hotkey=W
                  Buttonpos=1,0

                  [hlum]
                  Tip=(|cffffcc00E|r) Build Lumber Mill
                  Hotkey=E
                  Buttonpos=2,0

                  [hbla]
                  Tip=(|cffffcc00R|r) Build Blacksmith
                  Hotkey=R
                  Buttonpos=3,0

                  [hhou]
                  Tip=(|cffffcc00Q|r) Build Farm
                  Hotkey=Q
                  Buttonpos=0,0

                  [halt]
                  Tip=(|cffffcc00S|r) Build Altar of Kings
                  Hotkey=S
                  Buttonpos=1,1

                  [hars]
                  Tip=(|cffffcc00D|r) Build Arcane Sanctum
                  Hotkey=D
                  Buttonpos=2,1

                  [harm]
                  Tip=(|cffffcc00F|r) Build Workshop
                  Hotkey=F
                  Buttonpos=3,1

                  [hwtw]
                  Tip=(|cffffcc00A|r) Build Scout Tower
                  Hotkey=A
                  Buttonpos=0,1

                  [hgra]
                  Tip=(|cffffcc00X|r) Build Gryphon Aviary
                  Hotkey=X
                  Buttonpos=1,2

                  [hvlt]
                  Tip=(|cffffcc00C|r) Build Arcane Vault
                  Hotkey=C
                  Buttonpos=2,2

                  [adef]
                  Tip=(|cffffcc00Q|r) Defend
                  UnTip=(|cffffcc00Q|r) Stop Defend
                  Hotkey=Q
                  Unhotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [agyv]
                  Tip=True Sight
                  Buttonpos=0,0

                  [aflk]
                  Tip=Flak Cannons
                  Buttonpos=1,0

                  [agyb]
                  Tip=Flying Machine Bombs
                  Buttonpos=2,0

                  [afla]
                  Tip=(|cffffcc00W|r) Flare
                  Hotkey=W
                  Buttonpos=1,0

                  [afsh]
                  Tip=Fragmentation Shards
                  Buttonpos=2,0

                  [aroc]
                  Tip=Barrage
                  Buttonpos=0,0

                  [aslo]
                  Tip=(|cffffcc00Q|r) Slow
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [aivs]
                  Tip=(|cffffcc00W|r) Invisibility
                  Hotkey=W
                  Buttonpos=1,0

                  [aply]
                  Tip=(|cffffcc00E|r) Polymorph
                  Hotkey=E
                  Buttonpos=2,0

                  [ahea]
                  Tip=(|cffffcc00Q|r) Heal
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [adis]
                  Tip=(|cffffcc00W|r) Dispel Magic
                  Hotkey=W
                  Buttonpos=1,0

                  [ainf]
                  Tip=(|cffffcc00E|r) Inner Fire
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=E
                  Buttonpos=2,0
                  Unbuttonpos=2,0

                  [asps]
                  Tip=(|cffffcc00W|r) Spell Steal
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,0

                  [acmg]
                  Tip=(|cffffcc00Q|r) Control Magic
                  Hotkey=Q
                  Buttonpos=0,0

                  [afbk]
                  Tip=Feedback
                  Buttonpos=3,0

                  [amls]
                  Tip=(|cffffcc00Q|r) Aerial Shackles
                  Hotkey=Q
                  Buttonpos=0,0

                  [aclf]
                  Tip=(|cffffcc00W|r) Cloud
                  Hotkey=W
                  Buttonpos=1,0

                  [asth]
                  Tip=Storm Hammers
                  Buttonpos=0,0

                  [ahbz]
                  Tip=(|cffffcc00W|r) Blizzard - [|cffffcc00Level 1|r],(|cffffcc00W|r) Blizzard - [|cffffcc00Level 2|r],(|cffffcc00W|r) Blizzard - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00W|r) Learn Blizzard - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [ahwe]
                  Tip=(|cffffcc00Q|r) Summon Water Elemental - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Summon Water Elemental - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Summon Water Elemental - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Q|r) Learn Summon Water Elemental - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [ahab]
                  Tip=Brilliance Aura - [|cffffcc00Level 1|r],Brilliance Aura - [|cffffcc00Level 2|r],Brilliance Aura - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00E|r) Learn Brilliance Aura - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [ahmt]
                  Tip=(|cffffcc00R|r) Mass Teleport
                  Researchtip=(|cffffcc00R|r) Learn Mass Teleport
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [AHfs]
                  Tip=(|cffffcc00E|r) Flame Strike - [|cffffcc00Level 1|r],(|cffffcc00E|r) Flame Strike - [|cffffcc00Level 2|r],(|cffffcc00E|r) Flame Strike - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00E|r) Learn Flame Strike - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [AHbn]
                  Tip=(|cffffcc00W|r) Banish - [|cffffcc00Level 1|r],(|cffffcc00W|r) Banish - [|cffffcc00Level 2|r],(|cffffcc00W|r) Banish - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00W|r) Learn Banish - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [AHdr]
                  Tip=(|cffffcc00Q|r) Siphon Mana - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Siphon Mana - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Siphon Mana - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Q|r) Learn Siphon Mana - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [AHpx]
                  Tip=(|cffffcc00R|r) Summon Phoenix
                  Researchtip=(|cffffcc00R|r) Learn Summon Phoenix
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [AHtb]
                  Tip=(|cffffcc00Q|r) Storm Bolt - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Storm Bolt - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Storm Bolt - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Q|r) Learn Storm Bolt - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [AHtc]
                  Tip=(|cffffcc00W|r) Thunder Clap - [|cffffcc00Level 1|r],(|cffffcc00W|r) Thunder Clap - [|cffffcc00Level 2|r],(|cffffcc00W|r) Thunder Clap - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00W|r) Learn Thunder Clap - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [AHbh]
                  Tip=Bash - [|cffffcc00Level 1|r],Bash - [|cffffcc00Level 2|r],Bash - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00E|r) Learn Bash - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [AHav]
                  Tip=(|cffffcc00R|r) Avatar
                  Researchtip=(|cffffcc00R|r) Learn Avatar
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [AHhb]
                  Tip=(|cffffcc00Q|r) Holy Light - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Holy Light - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Holy Light - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Q|r) Learn Holy Light - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [AHds]
                  Tip=(|cffffcc00W|r) Divine Shield - [|cffffcc00Level 1|r],(|cffffcc00W|r) Divine Shield - [|cffffcc00Level 2|r],(|cffffcc00W|r) Divine Shield - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00W|r) Learn Divine Shield - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [AHad]
                  Tip=Devotion Aura - [|cffffcc00Level 1|r],Devotion Aura - [|cffffcc00Level 2|r],Devotion Aura - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00E|r) Learn Devotion Aura - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [AHre]
                  Tip=(|cffffcc00R|r) Resurrection
                  Researchtip=(|cffffcc00R|r) Learn Resurrection
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [Oshd]
                  Tip=(|cffffcc00A|r) Summon Shadow Hunter
                  Revivetip=(|cffffcc00A|r) Revive Shadow Hunter
                  Awakentip=(|cffffcc00A|r) Awaken Shadow Hunter
                  Hotkey=A
                  Buttonpos=0,1

                  [Obla]
                  Tip=(|cffffcc00Y|r) Summon Blademaster
                  Revivetip=(|cffffcc00Y|r) Revive Blademaster
                  Awakentip=(|cffffcc00Y|r) Awaken Blademaster
                  Hotkey=Y
                  Buttonpos=0,2

                  [Ofar]
                  Tip=(|cffffcc00X|r) Summon Far Seer
                  Revivetip=(|cffffcc00X|r) Revive Far Seer
                  Awakentip=(|cffffcc00X|r) Awaken Far Seer
                  Hotkey=X
                  Buttonpos=1,2

                  [Otch]
                  Tip=(|cffffcc00C|r) Summon Tauren Chieftain
                  Revivetip=(|cffffcc00C|r) Revive Tauren Chieftain
                  Awakentip=(|cffffcc00C|r) Awaken Tauren Chieftain
                  Hotkey=C
                  Buttonpos=2,2

                  [ogru]
                  Tip=(|cffffcc00Q|r) Train Grunt
                  Hotkey=Q
                  Buttonpos=0,0

                  [robs]
                  Tip=(|cffffcc00Y|r) Research Berserker Strength
                  Hotkey=Y
                  Buttonpos=0,2

                  [ohun]
                  Tip=(|cffffcc00W|r) Train Troll Headhunter
                  Hotkey=W
                  Buttonpos=1,0

                  [otbk]
                  Tip=(|cffffcc00W|r) Train Troll Berserker
                  Hotkey=W
                  Buttonpos=1,0

                  [rotr]
                  Tip=(|cffffcc00S|r) Research Troll Regeneration
                  Hotkey=S
                  Buttonpos=1,1

                  [robk]
                  Tip=(|cffffcc00X|r) Berserker Upgrade
                  Hotkey=X
                  Buttonpos=1,2

                  [ocat]
                  Tip=(|cffffcc00E|r) Train Demolisher
                  Hotkey=E
                  Buttonpos=2,0

                  [robf]
                  Tip=(|cffffcc00C|r) Burning Oil
                  Hotkey=C
                  Buttonpos=2,2

                  [orai]
                  Tip=(|cffffcc00Q|r) Train Raider
                  Hotkey=Q
                  Buttonpos=0,0

                  [owyv]
                  Tip=(|cffffcc00W|r) Train Wind Rider
                  Hotkey=W
                  Buttonpos=1,0

                  [okod]
                  Tip=(|cffffcc00E|r) Train Kodo Beast
                  Hotkey=E
                  Buttonpos=2,0

                  [otbr]
                  Tip=(|cffffcc00R|r) Train Troll Batrider
                  Hotkey=R
                  Buttonpos=3,0

                  [roen]
                  Tip=(|cffffcc00Y|r) Research Ensnare
                  Hotkey=Y
                  Buttonpos=0,2

                  [rovs]
                  Tip=(|cffffcc00X|r) Research Envenomed Weapon
                  Hotkey=X
                  Buttonpos=1,2

                  [rwdm]
                  Tip=(|cffffcc00C|r) Upgrade War Drums
                  Hotkey=C
                  Buttonpos=2,2

                  [rolf]
                  Tip=(|cffffcc00D|r) Research Liquid Fire
                  Hotkey=D
                  Buttonpos=2,1

                  [abtl]
                  Tip=(|cffffcc00Q|r) Battle Stations
                  Hotkey=Q
                  Buttonpos=0,0

                  [astd]
                  Tip=(|cffffcc00W|r) Stand Down
                  Hotkey=W
                  Buttonpos=1,0

                  [oshm]
                  Tip=(|cffffcc00Q|r) Train Shaman
                  Hotkey=Q
                  Buttonpos=0,0

                  [odoc]
                  Tip=(|cffffcc00W|r) Train Troll Witch Doctor
                  Hotkey=W
                  Buttonpos=1,0

                  [ospm]
                  Tip=(|cffffcc00E|r) Train Spirit Walker
                  Hotkey=E
                  Buttonpos=2,0

                  [rost]
                  Tip=(|cffffcc00Y|r) Shaman Adept Training,(|cffffcc00Y|r) Shaman Master Training
                  Hotkey=Y,Y
                  Buttonpos=0,2

                  [rowd]
                  Tip=(|cffffcc00X|r) Witch Doctor Adept Training,(|cffffcc00X|r) Witch Doctor Master Training
                  Hotkey=X,X
                  Buttonpos=1,2

                  [rowt]
                  Tip=(|cffffcc00C|r) Spirit Walker Adept Training,(|cffffcc00C|r) Spirit Walker Master Training
                  Hotkey=C,C
                  Buttonpos=2,2

                  [otau]
                  Tip=(|cffffcc00Q|r) Train Tauren
                  Hotkey=Q
                  Buttonpos=0,0

                  [rows]
                  Tip=(|cffffcc00Y|r) Research Pulverize
                  Hotkey=Y
                  Buttonpos=0,2

                  [opeo]
                  Tip=(|cffffcc00Q|r) Train Peon
                  Hotkey=Q
                  Buttonpos=0,0

                  [ropg]
                  Tip=(|cffffcc00W|r) Research Pillage
                  Hotkey=W
                  Buttonpos=1,0

                  [ropm]
                  Tip=(|cffffcc00X|r) Research Backpack
                  Hotkey=X
                  Buttonpos=1,2

                  [ostr]
                  Tip=(|cffffcc00Y|r) Upgrade To Stronghold
                  Hotkey=Y
                  Buttonpos=0,2

                  [ofrt]
                  Tip=(|cffffcc00Y|r) Upgrade To Fortress
                  Hotkey=Y
                  Buttonpos=0,2

                  [hslv]
                  Tip=(|cffffcc00Q|r) Purchase Healing Salve
                  Hotkey=Q
                  Buttonpos=0,0

                  [shas]
                  Tip=(|cffffcc00E|r) Purchase Scroll of Speed
                  Hotkey=E
                  Buttonpos=2,0

                  [oli2]
                  Tip=(|cffffcc00Y|r) Purchase Orb of Lightning
                  Hotkey=Y
                  Buttonpos=0,2

                  [tgrh]
                  Tip=(|cffffcc00X|r) Purchase Tiny Great Hall
                  Hotkey=X
                  Buttonpos=1,2

                  [rome]
                  Tip=(|cffffcc00Q|r) Upgrade to Steel Melee Weapons,(|cffffcc00Q|r) Upgrade to Thorium Melee Weapons,(|cffffcc00Q|r) Upgrade to Arcanite Melee Weapons
                  Hotkey=Q,Q,Q
                  Buttonpos=0,0

                  [rora]
                  Tip=(|cffffcc00W|r) Upgrade to Steel Ranged Weapons,(|cffffcc00W|r) Upgrade to Thorium Ranged Weapons,(|cffffcc00W|r) Upgrade to Arcanite Ranged Weapons
                  Hotkey=W,W,W
                  Buttonpos=1,0

                  [rosp]
                  Tip=(|cffffcc00E|r) Upgrade to Spiked Barricades,(|cffffcc00E|r) Upgrade to Improved Spiked Barricades,(|cffffcc00E|r) Upgrade to Advanced Spike Barricades
                  Hotkey=E,E,E
                  Buttonpos=2,0

                  [roar]
                  Tip=(|cffffcc00A|r) Upgrade to Steel Unit Armor,(|cffffcc00A|r) Upgrade to Thorium Unit Armor,(|cffffcc00A|r) Upgrade to Arcanite Unit Armor
                  Hotkey=A,A,A
                  Buttonpos=0,1

                  [rorb]
                  Tip=(|cffffcc00D|r) Reinforced Defenses
                  Hotkey=D
                  Buttonpos=2,1

                  [arep]
                  Tip=(|cffffcc00R|r) Repair
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=R
                  Buttonpos=3,0
                  Unbuttonpos=3,0

                  [cmdbuildorc]
                  Tip=(|cffffcc00Q|r) Build Structure
                  Hotkey=Q
                  [AObu]
                  Buttonpos=0,0

                  [ogre]
                  Tip=(|cffffcc00Y|r) Build Great Hall
                  Hotkey=Y
                  Buttonpos=0,2

                  [obar]
                  Tip=(|cffffcc00W|r) Build Barracks
                  Hotkey=W
                  Buttonpos=1,0

                  [ofor]
                  Tip=(|cffffcc00E|r) Build War Mill
                  Hotkey=E
                  Buttonpos=2,0

                  [owtw]
                  Tip=(|cffffcc00A|r) Build Watch Tower
                  Hotkey=A
                  Buttonpos=0,1

                  [otrb]
                  Tip=(|cffffcc00Q|r) Build Burrow
                  Hotkey=Q
                  Buttonpos=0,0

                  [oalt]
                  Tip=(|cffffcc00S|r) Build Altar of Storms
                  Hotkey=S
                  Buttonpos=1,1

                  [osld]
                  Tip=(|cffffcc00D|r) Build Spirit Lodge
                  Hotkey=D
                  Buttonpos=2,1

                  [obea]
                  Tip=(|cffffcc00F|r) Build Beastiary
                  Hotkey=F
                  Buttonpos=3,1

                  [otto]
                  Tip=(|cffffcc00X|r) Build Tauren Totem
                  Hotkey=X
                  Buttonpos=1,2

                  [ovln]
                  Tip=(|cffffcc00C|r) Build Voodoo Lounge
                  Hotkey=C
                  Buttonpos=2,2

                  [absk]
                  Tip=(|cffffcc00Q|r) Berserk
                  Hotkey=Q
                  Buttonpos=0,0

                  [abof]
                  Tip=Burning Oil
                  Buttonpos=1,0

                  [aens]
                  Tip=(|cffffcc00Q|r) Ensnare
                  Hotkey=Q
                  Buttonpos=0,0

                  [aven]
                  Tip=Envenomed Spears
                  Buttonpos=0,0

                  [adev]
                  Tip=(|cffffcc00Q|r) Devour
                  Hotkey=Q
                  Buttonpos=0,0

                  [aakb]
                  Tip=War Drums
                  Buttonpos=1,0

                  [auco]
                  Tip=(|cffffcc00Q|r) Unstable Concoction
                  Hotkey=Q
                  Buttonpos=0,0

                  [aliq]
                  Tip=Liquid Fire
                  Buttonpos=1,0

                  [aprg]
                  Tip=(|cffffcc00Q|r) Purge
                  Hotkey=Q
                  Buttonpos=0,0

                  [apg2]
                  Tip=(|cffffcc00Q|r) Purge
                  Hotkey=Q
                  Buttonpos=0,0

                  [alsh]
                  Tip=(|cffffcc00W|r) Lightning Shield
                  Hotkey=W
                  Buttonpos=1,0

                  [ablo]
                  Tip=(|cffffcc00E|r) Bloodlust
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=E
                  Buttonpos=2,0
                  Unbuttonpos=2,0

                  [aeye]
                  Tip=(|cffffcc00Q|r) Sentry Ward
                  Hotkey=Q
                  Buttonpos=0,0

                  [asta]
                  Tip=(|cffffcc00W|r) Stasis Trap
                  Hotkey=W
                  Buttonpos=1,0

                  [ahwd]
                  Tip=(|cffffcc00E|r) Healing Ward
                  Hotkey=E
                  Buttonpos=2,0

                  [aspl]
                  Tip=(|cffffcc00Q|r) Spirit Link
                  Hotkey=Q
                  Buttonpos=0,0

                  [adcn]
                  Tip=(|cffffcc00W|r) Disenchant
                  Hotkey=W
                  Buttonpos=1,0

                  [aast]
                  Tip=(|cffffcc00E|r) Ancestral Spirit
                  Hotkey=E
                  Buttonpos=2,0

                  [acpf]
                  Tip=(|cffffcc00R|r) Corporeal Form
                  UnTip=(|cffffcc00R|r) Ethereal Form
                  Hotkey=R
                  Unhotkey=R
                  Buttonpos=3,0
                  Unbuttonpos=3,0

                  [awar]
                  Tip=Pulverize
                  Buttonpos=0,0

                  [aocl]
                  Tip=(|cffffcc00Q|r) Chain Lightning - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Chain Lightning - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Chain Lightning - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Q|r) Learn Chain Lightning - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [aofs]
                  Tip=(|cffffcc00E|r) Far Sight - [|cffffcc00Level 1|r],(|cffffcc00E|r) Far Sight - [|cffffcc00Level 2|r],(|cffffcc00E|r) Far Sight - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00E|r) Learn Far Sight - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [aosf]
                  Tip=(|cffffcc00W|r) Feral Spirit - [|cffffcc00Level 1|r],(|cffffcc00W|r) Feral Spirit - [|cffffcc00Level 2|r],(|cffffcc00W|r) Feral Spirit - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00W|r) Learn Feral Spirit - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [aoeq]
                  Tip=(|cffffcc00R|r) Earthquake
                  Researchtip=(|cffffcc00R|r) Learn Earthquake
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [aosh]
                  Tip=(|cffffcc00Q|r) Shockwave - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Shockwave - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Shockwave - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Q|r) Learn Shockwave - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [aows]
                  Tip=(|cffffcc00W|r) War Stomp - [|cffffcc00Level 1|r],(|cffffcc00W|r) War Stomp - [|cffffcc00Level 2|r],(|cffffcc00W|r) War Stomp - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00W|r) Learn War Stomp - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [aoae]
                  Tip=Endurance Aura - [|cffffcc00Level 1|r],Endurance Aura - [|cffffcc00Level 2|r],Endurance Aura - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00E|r) Learn Endurance Aura - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [aore]
                  Tip=Reincarnation
                  Researchtip=(|cffffcc00R|r) Learn Reincarnation
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [aowk]
                  Tip=(|cffffcc00Q|r) Wind Walk - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Wind Walk - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Wind Walk - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Q|r) Learn Wind Walk - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [aomi]
                  Tip=(|cffffcc00W|r) Mirror Image - [|cffffcc00Level 1|r],(|cffffcc00W|r) Mirror Image - [|cffffcc00Level 2|r],(|cffffcc00W|r) Mirror Image - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00W|r) Learn Mirror Image - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [aocr]
                  Tip=Critical Strike - [|cffffcc00Level 1|r],Critical Strike - [|cffffcc00Level 2|r],Critical Strike - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00E|r) Learn Critical Strike - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [aoww]
                  Tip=(|cffffcc00R|r) Bladestorm
                  Researchtip=(|cffffcc00R|r) Learn Bladestorm
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [aohw]
                  Tip=(|cffffcc00Q|r) Healing Wave - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Healing Wave - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Healing Wave - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Q|r) Learn Healing Wave - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [aohx]
                  Tip=(|cffffcc00W|r) Hex - [|cffffcc00Level 1|r],(|cffffcc00W|r) Hex - [|cffffcc00Level 2|r],(|cffffcc00W|r) Hex - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00W|r) Learn Hex - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [aosw]
                  Tip=(|cffffcc00E|r) Serpent Ward - [|cffffcc00Level 1|r],(|cffffcc00E|r) Serpent Ward - [|cffffcc00Level 2|r],(|cffffcc00E|r) Serpent Ward - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00E|r) Learn Serpent Ward - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [aovd]
                  Tip=(|cffffcc00R|r) Big Bad Voodoo
                  Researchtip=(|cffffcc00R|r) Learn Big Bad Voodoo
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [uaco]
                  Tip=(|cffffcc00Q|r) Train Acolyte
                  Hotkey=Q
                  Buttonpos=0,0

                  [unp1]
                  Tip=(|cffffcc00Y|r) Upgrade to Halls of the Dead
                  Hotkey=Y
                  Buttonpos=0,2

                  [rupm]
                  Tip=(|cffffcc00X|r) Research Backpack
                  Hotkey=X
                  Buttonpos=1,2

                  [unp2]
                  Tip=(|cffffcc00Y|r) Upgrade to Black Citadel
                  Hotkey=Y
                  Buttonpos=0,2

                  [afr2]
                  Tip=Frost Attack
                  Buttonpos=1,0

                  [Udea]
                  Tip=(|cffffcc00Y|r) Summon Death Knight
                  Revivetip=(|cffffcc00Y|r) Revive Death Knight
                  Awakentip=(|cffffcc00Y|r) Awaken Death Knight
                  Hotkey=Y
                  Buttonpos=0,2

                  [Udre]
                  Tip=(|cffffcc00X|r) Summon Dreadlord
                  Revivetip=(|cffffcc00X|r) Revive Dreadlord
                  Awakentip=(|cffffcc00X|r) Awaken Dreadlord
                  Hotkey=X
                  Buttonpos=1,2

                  [Ulic]
                  Tip=(|cffffcc00C|r) Summon Lich
                  Revivetip=(|cffffcc00C|r) Revive Lich
                  Awakentip=(|cffffcc00C|r) Awaken Lich
                  Hotkey=C
                  Buttonpos=2,2

                  [Ucrl]
                  Tip=(|cffffcc00A|r) Summon Crypt Lord
                  Revivetip=(|cffffcc00A|r) Revive Crypt Lord
                  Awakentip=(|cffffcc00A|r) Awaken Crypt Lord
                  Hotkey=A
                  Buttonpos=0,1

                  [ugho]
                  Tip=(|cffffcc00Q|r) Train Ghoul
                  Hotkey=Q
                  Buttonpos=0,0

                  [ucry]
                  Tip=(|cffffcc00W|r) Train Crypt Fiend
                  Hotkey=W
                  Buttonpos=1,0

                  [ugar]
                  Tip=(|cffffcc00E|r) Train Gargoyle
                  Hotkey=E
                  Buttonpos=2,0

                  [ruac]
                  Tip=(|cffffcc00A|r) Research Cannibalize
                  Hotkey=A
                  Buttonpos=0,1

                  [rubu]
                  Tip=(|cffffcc00S|r) Research Burrow
                  Hotkey=S
                  Buttonpos=1,1

                  [rugf]
                  Tip=(|cffffcc00Y|r) Research Ghoul Frenzy
                  Hotkey=Y
                  Buttonpos=0,2

                  [ruwb]
                  Tip=(|cffffcc00X|r) Research Web
                  Hotkey=X
                  Buttonpos=1,2

                  [rusf]
                  Tip=(|cffffcc00C|r) Research Stone Form
                  Hotkey=C
                  Buttonpos=2,2

                  [umtw]
                  Tip=(|cffffcc00Q|r) Train Meat Wagon
                  Hotkey=Q
                  Buttonpos=0,0

                  [uabo]
                  Tip=(|cffffcc00W|r) Train Abomination
                  Hotkey=W
                  Buttonpos=1,0

                  [uobs]
                  Tip=(|cffffcc00E|r) Create Obsidian Statue
                  Hotkey=E
                  Buttonpos=2,0

                  [ruex]
                  Tip=(|cffffcc00Y|r) Research Exhume Corpses
                  Hotkey=Y
                  Buttonpos=0,2

                  [rupc]
                  Tip=(|cffffcc00X|r) Research Disease Cloud
                  Hotkey=X
                  Buttonpos=1,2

                  [rusp]
                  Tip=(|cffffcc00C|r) Research Destroyer Form
                  Hotkey=C
                  Buttonpos=2,2

                  [unec]
                  Tip=(|cffffcc00Q|r) Train Necromancer
                  Hotkey=Q
                  Buttonpos=0,0

                  [uban]
                  Tip=(|cffffcc00W|r) Train Banshee
                  Hotkey=W
                  Buttonpos=1,0

                  [rune]
                  Tip=(|cffffcc00Y|r) Necromancer Adept Training,(|cffffcc00Y|r) Necromancer Master Training
                  Hotkey=Y,Y
                  Buttonpos=0,2

                  [ruba]
                  Tip=(|cffffcc00X|r) Banshee Adept Training,(|cffffcc00X|r) Banshee Master Training
                  Hotkey=X,X
                  Buttonpos=1,2

                  [rusm]
                  Tip=(|cffffcc00D|r) Research Skeletal Mastery
                  Hotkey=D
                  Buttonpos=2,1

                  [rusl]
                  Tip=(|cffffcc00C|r) Research Skeletal Longevity
                  Hotkey=C
                  Buttonpos=2,2

                  [asac]
                  Tip=(|cffffcc00Q|r) Sacrifice
                  Hotkey=Q
                  Buttonpos=0,0

                  [ufro]
                  Tip=(|cffffcc00Q|r) Train Frost Wyrm
                  Hotkey=Q
                  Buttonpos=0,0

                  [rufb]
                  Tip=(|cffffcc00Y|r) Research Freezing Breath
                  Hotkey=Y
                  Buttonpos=0,2

                  [rume]
                  Tip=(|cffffcc00Q|r) Upgrade to Unholy Strength,(|cffffcc00Q|r) Improved Unholy Strength,(|cffffcc00Q|r) Advanced Unholy Strength
                  Hotkey=Q,Q,Q
                  Buttonpos=0,0

                  [ruar]
                  Tip=(|cffffcc00A|r) Upgrade to Unholy Armor,(|cffffcc00A|r) Improved Unholy Armor,(|cffffcc00A|r) Advanced Unholy Armor
                  Hotkey=A,A,A
                  Buttonpos=0,1

                  [rura]
                  Tip=(|cffffcc00W|r) Upgrade to Creature Attack,(|cffffcc00W|r) Improved Creature Attack,(|cffffcc00W|r) Advanced Creature Attack
                  Hotkey=W,W,W
                  Buttonpos=1,0

                  [rucr]
                  Tip=(|cffffcc00S|r) Upgrade to Creature Carapace,(|cffffcc00S|r) Improved Creature Carapace,(|cffffcc00S|r) Advanced Creature Carapace
                  Hotkey=S,S,S
                  Buttonpos=1,1

                  [uzg1]
                  Tip=(|cffffcc00W|r) Upgrade to Spirit Tower
                  Hotkey=W
                  Buttonpos=1,0

                  [uzg2]
                  Tip=(|cffffcc00Q|r) Upgrade to Nerubian Tower
                  Hotkey=Q
                  Buttonpos=0,0

                  [afra]
                  Tip=Frost Attack
                  Buttonpos=0,0

                  [rnec]
                  Tip=(|cffffcc00Q|r) Purchase Rod of Necromancy
                  Hotkey=Q
                  Buttonpos=0,0

                  [skul]
                  Tip=(|cffffcc00W|r) Purchase Sacrificial Skull
                  Hotkey=W
                  Buttonpos=1,0

                  [ocor]
                  Tip=(|cffffcc00Y|r) Purchase Orb of Corruption
                  Hotkey=Y
                  Buttonpos=0,2

                  [cmdbuildundead]
                  Tip=(|cffffcc00Q|r) Summon Building
                  Hotkey=Q
                  [AUbu]
                  Buttonpos=0,0

                  [auns]
                  Tip=(|cffffcc00W|r) Unsummon Building
                  Hotkey=W
                  Buttonpos=1,0

                  [arst]
                  Tip=(|cffffcc00R|r) Restore
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=R
                  Buttonpos=3,0
                  Unbuttonpos=3,0

                  [aaha]
                  Tip=(|cffffcc00F|r) Gather
                  Hotkey=F
                  Buttonpos=3,1

                  [alam]
                  Tip=(|cffffcc00E|r) Sacrifice
                  Hotkey=E
                  Buttonpos=2,0

                  [unpl]
                  Tip=(|cffffcc00Y|r) Summon Necropolis
                  Hotkey=Y
                  Buttonpos=0,2

                  [usep]
                  Tip=(|cffffcc00W|r) Summon Crypt
                  Hotkey=W
                  Buttonpos=1,0

                  [ugol]
                  Tip=(|cffffcc00A|r) Haunt Gold Mine
                  Hotkey=A
                  Buttonpos=0,1

                  [ugrv]
                  Tip=(|cffffcc00E|r) Summon Graveyard
                  Hotkey=E
                  Buttonpos=2,0

                  [uzig]
                  Tip=(|cffffcc00Q|r) Summon Ziggurat
                  Hotkey=Q
                  Buttonpos=0,0

                  [uaod]
                  Tip=(|cffffcc00S|r) Summon Altar
                  Hotkey=S
                  Buttonpos=1,1

                  [utod]
                  Tip=(|cffffcc00D|r) Summon Temple of the Damned
                  Hotkey=D
                  Buttonpos=2,1

                  [uslh]
                  Tip=(|cffffcc00F|r) Summon Slaughterhouse
                  Hotkey=F
                  Buttonpos=3,1

                  [usap]
                  Tip=(|cffffcc00R|r) Summon Sacrificial Pit
                  Hotkey=R
                  Buttonpos=3,0

                  [ubon]
                  Tip=(|cffffcc00X|r) Summon Boneyard
                  Hotkey=X
                  Buttonpos=1,2

                  [utom]
                  Tip=(|cffffcc00C|r) Summon Tomb of Relics
                  Hotkey=C
                  Buttonpos=2,2

                  [acan]
                  Tip=(|cffffcc00Q|r) Cannibalize
                  Hotkey=Q
                  Buttonpos=0,0

                  [ahrl]
                  Tip=(|cffffcc00F|r) Gather
                  UnTip=(|cffffcc00F|r) Return Resources
                  Hotkey=F
                  Unhotkey=F
                  Buttonpos=3,1
                  Unbuttonpos=3,1

                  [aweb]
                  Tip=(|cffffcc00Q|r) Web
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [abur]
                  Tip=(|cffffcc00W|r) Burrow
                  UnTip=(|cffffcc00W|r) Unburrow
                  Hotkey=W
                  Unhotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,0

                  [astn]
                  Tip=(|cffffcc00Q|r) Stone Form
                  UnTip=(|cffffcc00W|r) Gargoyle Form
                  Hotkey=Q
                  Unhotkey=W
                  Buttonpos=0,0
                  Unbuttonpos=1,0

                  [arai]
                  Tip=(|cffffcc00W|r) Raise Dead
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,0

                  [auhf]
                  Tip=(|cffffcc00E|r) Unholy Frenzy
                  Hotkey=E
                  Buttonpos=2,0

                  [auuf]
                  Tip=(|cffffcc00E|r) Incite Unholy Frenzy
                  Hotkey=E
                  Buttonpos=2,0

                  [acri]
                  Tip=(|cffffcc00Q|r) Cripple
                  Hotkey=Q
                  Buttonpos=0,0

                  [acrs]
                  Tip=(|cffffcc00Q|r) Curse
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [aams]
                  Tip=(|cffffcc00W|r) Anti-magic Shell
                  Hotkey=W
                  Buttonpos=1,0

                  [aam2]
                  Tip=(|cffffcc00W|r) Anti-magic Shell
                  Hotkey=W
                  Buttonpos=1,0

                  [apos]
                  Tip=(|cffffcc00E|r) Possession
                  Hotkey=E
                  Buttonpos=2,0

                  [aps2]
                  Tip=(|cffffcc00E|r) Possession
                  Hotkey=E
                  Buttonpos=2,0

                  [amel]
                  Tip=(|cffffcc00W|r) Get Corpse
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,0

                  [amed]
                  Tip=(|cffffcc00E|r) Drop All Corpses
                  Hotkey=E
                  Buttonpos=2,0

                  [apts]
                  Tip=Disease Cloud
                  Buttonpos=3,1

                  [aexh]
                  Tip=Exhume Corpses
                  Buttonpos=3,0

                  [acn2]
                  Tip=(|cffffcc00Q|r) Cannibalize
                  Hotkey=Q
                  Buttonpos=0,0

                  [aap1]
                  Tip=Disease Cloud
                  Buttonpos=1,0

                  [arpl]
                  Tip=(|cffffcc00Q|r) Essence of Blight
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [arpm]
                  Tip=(|cffffcc00W|r) Spirit Touch
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,0

                  [ubsp]
                  Tip=(|cffffcc00R|r) Morph into Destroyer
                  Hotkey=R
                  [Aave]
                  Buttonpos=3,0

                  [advm]
                  Tip=(|cffffcc00Q|r) Devour Magic
                  Hotkey=Q
                  Buttonpos=0,0

                  [afak]
                  Tip=(|cffffcc00R|r) Orb of Annihilation
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=R
                  Buttonpos=3,0
                  Unbuttonpos=3,0

                  [aabs]
                  Tip=(|cffffcc00W|r) Absorb Mana
                  Hotkey=W
                  Buttonpos=1,0

                  [atru]
                  Tip=True Sight
                  Buttonpos=0,0

                  [afrz]
                  Tip=Freezing Breath
                  Buttonpos=0,0

                  [audc]
                  Tip=(|cffffcc00Q|r) Death Coil - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Death Coil - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Death Coil - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Q|r) Learn Death Coil - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [audp]
                  Tip=(|cffffcc00W|r) Death Pact - [|cffffcc00Level 1|r],(|cffffcc00W|r) Death Pact - [|cffffcc00Level 2|r],(|cffffcc00W|r) Death Pact - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00W|r) Learn Death Pact - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [auau]
                  Tip=Unholy Aura - [|cffffcc00Level 1|r],Unholy Aura - [|cffffcc00Level 2|r],Unholy Aura - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00E|r) Learn Unholy Aura - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [auan]
                  Tip=(|cffffcc00R|r) Animate Dead - [|cffffcc00Level 1|r],(|cffffcc00R|r) Animate Dead - [|cffffcc00Level 2|r],(|cffffcc00R|r) Animate Dead - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Animate Dead - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [aucs]
                  Tip=(|cffffcc00Q|r) Carrion Swarm - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Carrion Swarm - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Carrion Swarm - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Q|r) Learn Carrion Swarm - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [ausl]
                  Tip=(|cffffcc00W|r) Sleep - [|cffffcc00Level 1|r],(|cffffcc00W|r) Sleep - [|cffffcc00Level 2|r],(|cffffcc00W|r) Sleep - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00W|r) Learn Sleep - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [auav]
                  Tip=Vampiric Aura - [|cffffcc00Level 1|r],Vampiric Aura - [|cffffcc00Level 2|r],Vampiric Aura - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00E|r) Learn Vampiric Aura - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [auin]
                  Tip=(|cffffcc00R|r) Inferno - [|cffffcc00Level 1|r],(|cffffcc00R|r) Inferno - [|cffffcc00Level 2|r],(|cffffcc00R|r) Inferno - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Inferno - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [aufn]
                  Tip=(|cffffcc00Q|r) Frost Nova - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Frost Nova - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Frost Nova - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Q|r) Learn Frost Nova - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [aufu]
                  Tip=(|cffffcc00W|r) Frost Armor - [|cffffcc00Level 1|r],(|cffffcc00W|r) Frost Armor - [|cffffcc00Level 2|r],(|cffffcc00W|r) Frost Armor - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00W|r) Learn Frost Armor - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,0
                  Researchbuttonpos=1,0

                  [audr]
                  Tip=(|cffffcc00E|r) Dark Ritual - [|cffffcc00Level 1|r],(|cffffcc00E|r) Dark Ritual - [|cffffcc00Level 2|r],(|cffffcc00E|r) Dark Ritual - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00E|r) Learn Dark Ritual - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [audd]
                  Tip=(|cffffcc00R|r) Death and Decay - [|cffffcc00Level 1|r],(|cffffcc00R|r) Death and Decay - [|cffffcc00Level 2|r],(|cffffcc00R|r) Death and Decay - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Death and Decay - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [auim]
                  Tip=(|cffffcc00Q|r) Impale - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Impale - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Impale - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Q|r) Learn Impale - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [auts]
                  Tip=Spiked Carapace - [|cffffcc00Level 1|r],Spiked Carapace - [|cffffcc00Level 2|r],Spiked Carapace - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00W|r) Learn Spiked Carapace - [|cffffcc00Level %d|r]
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [aucb]
                  Tip=(|cffffcc00E|r) Carrion Beetles - [|cffffcc00Level 1|r],(|cffffcc00E|r) Carrion Beetles - [|cffffcc00Level 2|r],(|cffffcc00E|r) Carrion Beetles - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00E|r) Learn Carrion Beetles - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Unbuttonpos=2,0
                  Researchbuttonpos=2,0

                  [auls]
                  Tip=(|cffffcc00R|r) Locust Swarm - [|cffffcc00Level 1|r],(|cffffcc00R|r) Locust Swarm - [|cffffcc00Level 2|r],(|cffffcc00R|r) Locust Swarm - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Locust Swarm - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [anpi]
                  Tip=Permanent Immolation
                  Buttonpos=0,0

                  [abu2]
                  Tip=(|cffffcc00Q|r) Burrow
                  UnTip=(|cffffcc00Q|r) Unburrow
                  Hotkey=Q
                  Unhotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [abu3]
                  Tip=(|cffffcc00Q|r) Burrow
                  UnTip=(|cffffcc00Q|r) Unburrow
                  Hotkey=Q
                  Unhotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [aro1]
                  Tip=(|cffffcc00R|r) Root
                  UnTip=(|cffffcc00R|r) Uproot
                  Hotkey=R
                  Unhotkey=R
                  Buttonpos=3,0
                  Unbuttonpos=3,0

                  [aro2]
                  Tip=(|cffffcc00R|r) Root
                  UnTip=(|cffffcc00R|r) Uproot
                  Hotkey=R
                  Unhotkey=R
                  Buttonpos=3,0
                  Unbuttonpos=3,0

                  [aeat]
                  Tip=(|cffffcc00Q|r) Eat Tree
                  Hotkey=Q
                  Buttonpos=0,0

                  [slo2]
                  Tip=(|cffffcc00Q|r) Load Wisp
                  Hotkey=Q
                  Buttonpos=0,0

                  [adri]
                  Tip=(|cffffcc00W|r) Unload All
                  Hotkey=W
                  Buttonpos=1,0

                  [ewsp]
                  Tip=(|cffffcc00Q|r) Train Wisp
                  Hotkey=Q
                  Buttonpos=0,0

                  [renb]
                  Tip=(|cffffcc00X|r) Research Nature's Blessing
                  Hotkey=X
                  Buttonpos=1,2

                  [repm]
                  Tip=(|cffffcc00C|r) Research Backpack
                  Hotkey=C
                  Buttonpos=2,2

                  [etoa]
                  Tip=(|cffffcc00Y|r) Upgrade to Tree of Ages
                  Hotkey=Y
                  Buttonpos=0,2

                  [aent]
                  Tip=(|cffffcc00W|r) Entangle Gold Mine
                  Hotkey=W
                  Buttonpos=1,0

                  [etoe]
                  Tip=(|cffffcc00Y|r) Upgrade to Tree of Eternity
                  Hotkey=Y
                  Buttonpos=0,2

                  [ambt]
                  Tip=(|cffffcc00Q|r) Replenish Mana and Life
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [Edem]
                  Tip=(|cffffcc00Y|r) Summon Demon Hunter
                  Revivetip=(|cffffcc00Y|r) Revive Demon Hunter
                  Awakentip=(|cffffcc00Y|r) Awaken Demon Hunter
                  Hotkey=Y
                  Buttonpos=0,2

                  [Ekee]
                  Tip=(|cffffcc00X|r) Summon Keeper of the Grove
                  Revivetip=(|cffffcc00X|r) Revive Keeper of the Grove
                  Awakentip=(|cffffcc00X|r) Awaken Keeper of the Grove
                  Hotkey=X
                  Buttonpos=1,2

                  [Emoo]
                  Tip=(|cffffcc00C|r) Summon Priestess of the Moon
                  Revivetip=(|cffffcc00C|r) Revive Priestess of the Moon
                  Awakentip=(|cffffcc00C|r) Awaken Priestess of the Moon
                  Hotkey=C
                  Buttonpos=2,2

                  [Ewar]
                  Tip=(|cffffcc00A|r) Summon Warden
                  Revivetip=(|cffffcc00A|r) Revive Warden
                  Awakentip=(|cffffcc00A|r) Awaken Warden
                  Hotkey=A
                  Buttonpos=0,1

                  [earc]
                  Tip=(|cffffcc00Q|r) Train Archer
                  Hotkey=Q
                  Buttonpos=0,0

                  [esen]
                  Tip=(|cffffcc00W|r) Train Huntress
                  Hotkey=W
                  Buttonpos=1,0

                  [ebal]
                  Tip=(|cffffcc00E|r) Train Glaive Thrower
                  Hotkey=E
                  Buttonpos=2,0

                  [reib]
                  Tip=(|cffffcc00A|r) Research Improved Bows
                  Hotkey=A
                  Buttonpos=0,1

                  [resc]
                  Tip=(|cffffcc00S|r) Research Sentinel
                  Hotkey=S
                  Buttonpos=1,1

                  [remk]
                  Tip=(|cffffcc00Y|r) Research Marksmanship
                  Hotkey=Y
                  Buttonpos=0,2

                  [remg]
                  Tip=(|cffffcc00X|r) Upgrade Moon Glaive
                  Hotkey=X
                  Buttonpos=1,2

                  [repb]
                  Tip=(|cffffcc00D|r) Research Vorpal Blades
                  Hotkey=D
                  Buttonpos=2,1

                  [resm]
                  Tip=(|cffffcc00Q|r) Upgrade to Strength of the Moon,(|cffffcc00Q|r) Upgrade to Improved Strength of the Moon,(|cffffcc00Q|r) Upgrade to Advanced Strength of the Moon
                  Hotkey=Q,Q,Q
                  Buttonpos=0,0

                  [rema]
                  Tip=(|cffffcc00A|r) Upgrade to Moon Armor,(|cffffcc00A|r) Upgrade to Improved Moon Armor,(|cffffcc00A|r) Upgrade to Advanced Moon Armor
                  Hotkey=A,A,A
                  Buttonpos=0,1

                  [resw]
                  Tip=(|cffffcc00W|r) Upgrade to Strength of the Wild,(|cffffcc00W|r) Upgrade to Improved Strength of the Wild,(|cffffcc00W|r) Upgrade to Advanced Strength of the Wild
                  Hotkey=W,W,W
                  Buttonpos=1,0

                  [rerh]
                  Tip=(|cffffcc00S|r) Upgrade to Reinforced Hides,(|cffffcc00S|r) Upgrade to Improved Reinforced Hides,(|cffffcc00S|r) Upgrade to Advanced Reinforced Hides
                  Hotkey=S,S,S
                  Buttonpos=1,1

                  [reuv]
                  Tip=(|cffffcc00E|r) Research Ultravision
                  Hotkey=E
                  Buttonpos=2,0

                  [rews]
                  Tip=(|cffffcc00R|r) Research Well Spring
                  Hotkey=R
                  Buttonpos=3,0

                  [edry]
                  Tip=(|cffffcc00Q|r) Train Dryad
                  Hotkey=Q
                  Buttonpos=0,0

                  [edoc]
                  Tip=(|cffffcc00W|r) Train Druid of the Claw
                  Hotkey=W
                  Buttonpos=1,0

                  [emtg]
                  Tip=(|cffffcc00E|r) Train Mountain Giant
                  Hotkey=E
                  Buttonpos=2,0

                  [resi]
                  Tip=(|cffffcc00Y|r) Research Abolish Magic
                  Hotkey=Y
                  Buttonpos=0,2

                  [reeb]
                  Tip=(|cffffcc00S|r) Research Mark of the Claw
                  Hotkey=S
                  Buttonpos=1,1

                  [redc]
                  Tip=(|cffffcc00X|r) Druid of the Claw Adept Training,(|cffffcc00X|r) Druid of the Claw Master Training
                  Hotkey=X,X
                  Buttonpos=1,2

                  [rehs]
                  Tip=(|cffffcc00D|r) Research Hardened Skin
                  Hotkey=D
                  Buttonpos=2,1

                  [rers]
                  Tip=(|cffffcc00C|r) Research Resistant Skin
                  Hotkey=C
                  Buttonpos=2,2

                  [ehip]
                  Tip=(|cffffcc00Q|r) Train Hippogryph
                  Hotkey=Q
                  Buttonpos=0,0

                  [edot]
                  Tip=(|cffffcc00W|r) Train Druid of the Talon
                  Hotkey=W
                  Buttonpos=1,0

                  [efdr]
                  Tip=(|cffffcc00E|r) Train Fairie Dragon
                  Hotkey=E
                  Buttonpos=2,0

                  [reht]
                  Tip=(|cffffcc00Y|r) Research Hippogryph Taming
                  Hotkey=Y
                  Buttonpos=0,2

                  [reec]
                  Tip=(|cffffcc00S|r) Research Mark of the Talon
                  Hotkey=S
                  Buttonpos=1,1

                  [redt]
                  Tip=(|cffffcc00X|r) Druid of the Talon Adept Training,(|cffffcc00X|r) Druid of the Talon Master Training
                  Hotkey=X,X
                  Buttonpos=1,2

                  [echm]
                  Tip=(|cffffcc00Q|r) Train Chimaera
                  Hotkey=Q
                  Buttonpos=0,0

                  [recb]
                  Tip=(|cffffcc00Y|r) Research Corrosive Breath
                  Hotkey=Y
                  Buttonpos=0,2

                  [moon]
                  Tip=(|cffffcc00Q|r) Purchase Moonstone
                  Hotkey=Q
                  Buttonpos=0,0

                  [spre]
                  Tip=(|cffffcc00F|r) Purchase Staff of Preservation
                  Hotkey=F
                  Buttonpos=3,1

                  [oven]
                  Tip=(|cffffcc00Y|r) Purchase Orb of Venom
                  Hotkey=Y
                  Buttonpos=0,2

                  [pams]
                  Tip=(|cffffcc00X|r) Purchase Anti-magic Potion
                  Hotkey=X
                  Buttonpos=1,2

                  [cmdbuildnightelf]
                  Tip=(|cffffcc00Q|r) Create Building
                  Hotkey=Q
                  [AEbu]
                  Buttonpos=0,0

                  [aren]
                  Tip=(|cffffcc00R|r) Renew
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=R
                  Buttonpos=3,0
                  Unbuttonpos=3,0

                  [adtn]
                  Tip=(|cffffcc00E|r) Detonate
                  Hotkey=E
                  Buttonpos=2,0

                  [awha]
                  Tip=(|cffffcc00F|r) Gather
                  Hotkey=F
                  Buttonpos=3,1

                  [etol]
                  Tip=(|cffffcc00Y|r) Create Tree of Life
                  Hotkey=Y
                  Buttonpos=0,2

                  [eaom]
                  Tip=(|cffffcc00W|r) Create Ancient of War
                  Hotkey=W
                  Buttonpos=1,0

                  [edob]
                  Tip=(|cffffcc00E|r) Create Hunter's Hall
                  Hotkey=E
                  Buttonpos=2,0

                  [etrp]
                  Tip=(|cffffcc00A|r) Create Ancient Protector
                  Hotkey=A
                  Buttonpos=0,1

                  [emow]
                  Tip=(|cffffcc00Q|r) Create Moon Well
                  Hotkey=Q
                  Buttonpos=0,0

                  [eate]
                  Tip=(|cffffcc00S|r) Create Altar of Elders
                  Hotkey=S
                  Buttonpos=1,1

                  [eaoe]
                  Tip=(|cffffcc00D|r) Create Ancient of Lore
                  Hotkey=D
                  Buttonpos=2,1

                  [eaow]
                  Tip=(|cffffcc00F|r) Create Ancient of Wind
                  Hotkey=F
                  Buttonpos=3,1

                  [edos]
                  Tip=(|cffffcc00X|r) Create Chimaera Roost
                  Hotkey=X
                  Buttonpos=1,2

                  [eden]
                  Tip=(|cffffcc00C|r) Create Ancient of Wonders
                  Hotkey=C
                  Buttonpos=2,2

                  [aco2]
                  Tip=(|cffffcc00Q|r) Mount Hippogryph
                  Hotkey=Q
                  Buttonpos=0,0

                  [aegr]
                  Tip=Elune's Grace
                  Buttonpos=1,0

                  [aesn]
                  Tip=(|cffffcc00Q|r) Sentinel
                  Hotkey=Q
                  Buttonpos=0,0

                  [amgl]
                  Tip=Moon Glaive
                  Buttonpos=1,0

                  [aimp]
                  Tip=Vorpal Blades
                  Buttonpos=1,0

                  [aadm]
                  Tip=(|cffffcc00Q|r) Abolish Magic
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [aspo]
                  Tip=Slow Poison
                  Buttonpos=1,0

                  [aroa]
                  Tip=(|cffffcc00R|r) Roar
                  Hotkey=R
                  Buttonpos=3,0

                  [ara2]
                  Tip=(|cffffcc00R|r) Roar
                  Hotkey=R
                  Buttonpos=3,0

                  [arej]
                  Tip=(|cffffcc00Q|r) Rejuvenation
                  Hotkey=Q
                  Buttonpos=0,0

                  [abrf]
                  Tip=(|cffffcc00W|r) Bear Form
                  UnTip=(|cffffcc00W|r) Night Elf Form
                  Hotkey=W
                  Unhotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,0

                  [atau]
                  Tip=(|cffffcc00Q|r) Taunt
                  Hotkey=Q
                  Buttonpos=0,0

                  [agra]
                  Tip=(|cffffcc00W|r) War Club
                  Hotkey=W
                  Buttonpos=1,0

                  [assk]
                  Tip=Hardened Skin
                  Buttonpos=2,0

                  [arsk]
                  Tip=Resistant Skin
                  Buttonpos=3,0

                  [aco3]
                  Tip=(|cffffcc00Q|r) Pick up Archer
                  Hotkey=Q
                  Buttonpos=0,0

                  [adec]
                  Tip=(|cffffcc00Q|r) Dismount Archer & Hippogryph
                  Hotkey=Q
                  Buttonpos=0,0

                  [afae]
                  Tip=(|cffffcc00Q|r) Faerie Fire
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [acyc]
                  Tip=(|cffffcc00W|r) Cyclone
                  Hotkey=W
                  Buttonpos=1,0

                  [arav]
                  Tip=(|cffffcc00R|r) Storm Crow Form
                  UnTip=(|cffffcc00R|r) Night Elf Form
                  Hotkey=R
                  Unhotkey=R
                  Buttonpos=3,0
                  Unbuttonpos=3,0

                  [apsh]
                  Tip=(|cffffcc00Q|r) Phase Shift
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [amfl]
                  Tip=(|cffffcc00W|r) Mana Flare
                  UnTip=(|cffffcc00W|r) Stop Mana Flare
                  Hotkey=W
                  Unhotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,0

                  [acor]
                  Tip=Corrosive Breath
                  Buttonpos=0,0

                  [aesr]
                  Tip=(|cffffcc00Q|r) Sentinel
                  Hotkey=Q
                  Buttonpos=0,0

                  [aemb]
                  Tip=(|cffffcc00Q|r) Mana Burn - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Mana Burn - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Mana Burn - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Q|r) Learn Mana Burn - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [aeim]
                  Tip=(|cffffcc00W|r) Activate Immolation - [|cffffcc00Level 1|r],(|cffffcc00W|r) Activate Immolation - [|cffffcc00Level 2|r],(|cffffcc00W|r) Activate Immolation - [|cffffcc00Level 3|r]
                  UnTip=(|cffffcc00W|r) Deactivate Immolation
                  Researchtip=(|cffffcc00W|r) Learn Activate Immolation - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Unhotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,0
                  Researchbuttonpos=1,0

                  [aeev]
                  Tip=Evasion - [|cffffcc00Level 1|r],Evasion - [|cffffcc00Level 2|r],Evasion - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00E|r) Learn Evasion - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [aeme]
                  Tip=(|cffffcc00R|r) Metamorphosis
                  Researchtip=(|cffffcc00R|r) Learn Metamorphosis
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [aeer]
                  Tip=(|cffffcc00Q|r) Entangling Roots - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Entangling Roots - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Entangling Roots - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Q|r) Learn Entangling Roots - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [aefn]
                  Tip=(|cffffcc00W|r) Force of Nature - [|cffffcc00Level 1|r],(|cffffcc00W|r) Force of Nature - [|cffffcc00Level 2|r],(|cffffcc00W|r) Force of Nature - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00W|r) Learn Force of Nature - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [aeah]
                  Tip=Thorns Aura - [|cffffcc00Level 1|r],Thorns Aura - [|cffffcc00Level 2|r],Thorns Aura - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00E|r) Learn Thorns Aura - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [aetq]
                  Tip=(|cffffcc00R|r) Tranquility
                  Researchtip=(|cffffcc00R|r) Learn Tranquility
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [aest]
                  Tip=(|cffffcc00Q|r) Scout - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Scout - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Scout - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Q|r) Learn Scout - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [ahfa]
                  Tip=(|cffffcc00W|r) Searing Arrows - [|cffffcc00Level 1|r],(|cffffcc00W|r) Searing Arrows - [|cffffcc00Level 2|r],(|cffffcc00W|r) Searing Arrows - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00W|r) Learn Searing Arrows - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,0
                  Researchbuttonpos=1,0

                  [aear]
                  Tip=Trueshot Aura - [|cffffcc00Level 1|r],Trueshot Aura - [|cffffcc00Level 2|r],Trueshot Aura - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00E|r) Learn Trueshot Aura - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [aesf]
                  Tip=(|cffffcc00R|r) Starfall
                  Researchtip=(|cffffcc00R|r) Learn Starfall
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [aebl]
                  Tip=(|cffffcc00W|r) Blink - [|cffffcc00Level 1|r],(|cffffcc00W|r) Blink - [|cffffcc00Level 2|r],(|cffffcc00W|r) Blink - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00W|r) Learn Blink - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [aefk]
                  Tip=(|cffffcc00Q|r) Fan of Knives - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Fan of Knives - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Fan of Knives - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Q|r) Learn Fan of Knives - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [aesh]
                  Tip=(|cffffcc00E|r) Shadow Strike - [|cffffcc00Level 1|r],(|cffffcc00E|r) Shadow Strike - [|cffffcc00Level 2|r],(|cffffcc00E|r) Shadow Strike - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00E|r) Learn Shadow Strike - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [aesv]
                  Tip=(|cffffcc00R|r) Vengeance
                  Researchtip=(|cffffcc00R|r) Learn Vengeance
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [adtg]
                  Tip=True Sight
                  Buttonpos=0,0

                  [avng]
                  Tip=(|cffffcc00Q|r) Spirit of Vengeance
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [NCpn]
                  Tip=(|cffffcc00Q|r) Train Chaos Peon
                  Hotkey=Q
                  Buttonpos=0,0

                  [NChg]
                  Tip=(|cffffcc00Q|r) Train Chaos Grunt
                  Hotkey=Q
                  Buttonpos=0,0

                  [NChr]
                  Tip=(|cffffcc00Q|r) Train Chaos Rider
                  Hotkey=Q
                  Buttonpos=0,0

                  [NCkb]
                  Tip=(|cffffcc00W|r) Train Chaos Kodo Beast
                  Hotkey=W
                  Buttonpos=1,0

                  [NChw]
                  Tip=(|cffffcc00Q|r) Train Chaos Warlock
                  Hotkey=Q
                  Buttonpos=0,0

                  [awfb]
                  Tip=(|cffffcc00Q|r) Firebolt
                  Hotkey=Q
                  Buttonpos=0,0

                  [suhf]
                  Tip=(|cffffcc00W|r) Unholy Frenzy
                  Hotkey=W
                  Buttonpos=1,0

                  [scri]
                  Tip=(|cffffcc00E|r) Cripple
                  Hotkey=E
                  Buttonpos=2,0

                  [nhew]
                  Tip=(|cffffcc00Q|r) Train Worker
                  Hotkey=Q
                  Buttonpos=0,0

                  [hhes]
                  Tip=(|cffffcc00Q|r) Train Swordsman
                  Hotkey=Q
                  Buttonpos=0,0

                  [nhea]
                  Tip=(|cffffcc00W|r) Train Archer
                  Hotkey=W
                  Buttonpos=1,0

                  [net2]
                  Tip=(|cffffcc00Y|r) Upgrade to Advanced Energy Tower
                  Hotkey=Y
                  Buttonpos=0,2

                  [nbt2]
                  Tip=(|cffffcc00Y|r) Upgrade to Advanced Boulder Tower
                  Hotkey=Y
                  Buttonpos=0,2

                  [nft2]
                  Tip=(|cffffcc00Y|r) Upgrade to Advanced Flame Tower
                  Hotkey=Y
                  Buttonpos=0,2

                  [ndt2]
                  Tip=(|cffffcc00Y|r) Upgrade to Advanced Cold Tower
                  Hotkey=Y
                  Buttonpos=0,2

                  [ntx2]
                  Tip=(|cffffcc00Y|r) Upgrade to Advanced Death Tower
                  Hotkey=Y
                  Buttonpos=0,2

                  [net1]
                  Tip=(|cffffcc00Q|r) Build Energy Tower
                  Hotkey=Q
                  Buttonpos=0,0

                  [nbt1]
                  Tip=(|cffffcc00W|r) Build Boulder Tower
                  Hotkey=W
                  Buttonpos=1,0

                  [nft1]
                  Tip=(|cffffcc00A|r) Build Flame Tower
                  Hotkey=A
                  Buttonpos=0,1

                  [ndt1]
                  Tip=(|cffffcc00S|r) Build Cold Tower
                  Hotkey=S
                  Buttonpos=1,1

                  [ntt1]
                  Tip=(|cffffcc00Y|r) Build Death Tower
                  Hotkey=Y
                  Buttonpos=0,2

                  [ssil]
                  Tip=(|cffffcc00E|r) Purchase Staff of Silence
                  Hotkey=E
                  Buttonpos=2,0

                  [nmpe]
                  Tip=(|cffffcc00Q|r) Train Mur'gul Slave
                  Hotkey=Q
                  Buttonpos=0,0

                  [rnat]
                  Tip=(|cffffcc00Y|r) Upgrade to Coral Blades,(|cffffcc00Y|r) Upgrade to Chitinous Blades,(|cffffcc00Y|r) Upgrade to Razorspine Blades
                  Hotkey=Y,Y,Y
                  Buttonpos=0,2

                  [nnmg]
                  Tip=(|cffffcc00W|r) Train Mur'gul Reaver
                  Hotkey=W
                  Buttonpos=1,0

                  [rnam]
                  Tip=(|cffffcc00X|r) Upgrade to Coral Scales,(|cffffcc00X|r) Upgrade to Chitinous Scales,(|cffffcc00X|r) Upgrade to Razorspine Scales
                  Hotkey=X,X,X
                  Buttonpos=1,2

                  [nmyr]
                  Tip=(|cffffcc00Q|r) Train Naga Myrmidon
                  Hotkey=Q
                  Buttonpos=0,0

                  [nsnp]
                  Tip=(|cffffcc00W|r) Train Snap Dragon
                  Hotkey=W
                  Buttonpos=1,0

                  [nhyc]
                  Tip=(|cffffcc00E|r) Train Dragon Turtle
                  Hotkey=E
                  Buttonpos=2,0

                  [rnen]
                  Tip=(|cffffcc00Y|r) Research Ensnare
                  Hotkey=Y
                  Buttonpos=0,2

                  [nnsw]
                  Tip=(|cffffcc00Q|r) Train Naga Siren
                  Hotkey=Q
                  Buttonpos=0,0

                  [nwgs]
                  Tip=(|cffffcc00W|r) Train Couatl
                  Hotkey=W
                  Buttonpos=1,0

                  [rnsw]
                  Tip=(|cffffcc00Y|r) Research Naga Siren Adept Training,(|cffffcc00Y|r) Research Naga Siren Master Training
                  Hotkey=Y,Y
                  Buttonpos=0,2

                  [rnsi]
                  Tip=(|cffffcc00X|r) Research Abolish Magic
                  Hotkey=X
                  Buttonpos=1,2

                  [aevi]
                  Tip=(|cffffcc00R|r) Metamorphosis
                  Researchtip=(|cffffcc00R|r) Learn Metamorphosis
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [cmdbuildnaga]
                  Tip=(|cffffcc00Q|r) Build Structure
                  Hotkey=Q
                  [AAbu]
                  Buttonpos=0,0

                  [anha]
                  Tip=(|cffffcc00F|r) Gather
                  UnTip=(|cffffcc00F|r) Return Resources
                  Hotkey=F
                  Unhotkey=F
                  Buttonpos=3,1
                  Unbuttonpos=3,1

                  [nntt]
                  Tip=(|cffffcc00Y|r) Build Temple of Tides
                  Hotkey=Y
                  Buttonpos=0,2

                  [nnsg]
                  Tip=(|cffffcc00W|r) Build Spawning Grounds
                  Hotkey=W
                  Buttonpos=1,0

                  [nnfm]
                  Tip=(|cffffcc00Q|r) Build Coral Bed
                  Hotkey=Q
                  Buttonpos=0,0

                  [nntg]
                  Tip=(|cffffcc00A|r) Build Tidal Guardian
                  Hotkey=A
                  Buttonpos=0,1

                  [nnsa]
                  Tip=(|cffffcc00D|r) Build Shrine of Azshara
                  Hotkey=D
                  Buttonpos=2,1

                  [nnad]
                  Tip=(|cffffcc00S|r) Build Altar of the Depths
                  Hotkey=S
                  Buttonpos=1,1

                  [anen]
                  Tip=(|cffffcc00Q|r) Ensnare
                  Hotkey=Q
                  Buttonpos=0,0

                  [asb1]
                  Tip=(|cffffcc00W|r) Submerge
                  UnTip=(|cffffcc00W|r) Surface
                  Hotkey=W
                  Unhotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,0

                  [anth]
                  Tip=Spiked Shell
                  Buttonpos=1,0

                  [ansk]
                  Tip=Hardened Skin
                  Buttonpos=2,0

                  [anpa]
                  Tip=(|cffffcc00Q|r) Parasite
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [acfu]
                  Tip=(|cffffcc00W|r) Frost Armor
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,0

                  [acny]
                  Tip=(|cffffcc00E|r) Cyclone
                  Hotkey=E
                  Buttonpos=2,0

                  [andm]
                  Tip=(|cffffcc00Q|r) Abolish Magic
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [asb2]
                  Tip=(|cffffcc00R|r) Submerge
                  UnTip=(|cffffcc00R|r) Surface
                  Hotkey=R
                  Unhotkey=R
                  Buttonpos=3,0
                  Unbuttonpos=3,0

                  [acs7]
                  Tip=(|cffffcc00W|r) Feral Spirit - [|cffffcc00Level 1|r],(|cffffcc00W|r) Feral Spirit - [|cffffcc00Level 2|r],(|cffffcc00W|r) Feral Spirit - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00W|r) Learn Feral Spirit - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [anr2]
                  Tip=Reincarnation
                  Researchtip=(|cffffcc00R|r) Learn Reincarnation
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [arsg]
                  Tip=(|cffffcc00Q|r) Summon Misha - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Summon Misha - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Summon Misha - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Summon Misha - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Summon Misha - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [arsq]
                  Tip=(|cffffcc00W|r) Summon Quilbeast - [|cffffcc00Level 1|r],(|cffffcc00W|r) Summon Quilbeast - [|cffffcc00Level 2|r],(|cffffcc00W|r) Summon Quilbeast - [|cffffcc00Level 3|r],(|cffffcc00W|r) Summon Quilbeast - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Summon Quilbeast - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [ansb]
                  Tip=(|cffffcc00E|r) Storm Bolt - [|cffffcc00Level 1|r],(|cffffcc00E|r) Storm Bolt - [|cffffcc00Level 2|r],(|cffffcc00E|r) Storm Bolt - [|cffffcc00Level 3|r],(|cffffcc00E|r) Storm Bolt - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Storm Bolt - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [arsp]
                  Tip=(|cffffcc00R|r) Stampede - [|cffffcc00Level 1|r],(|cffffcc00R|r) Stampede - [|cffffcc00Level 2|r]
                  Researchtip=(|cffffcc00R|r) Learn Stampede - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [ancf]
                  Tip=(|cffffcc00Q|r) Breath Of Fire - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Breath Of Fire - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Breath Of Fire - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Breath Of Fire - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Breath Of Fire - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [acdh]
                  Tip=(|cffffcc00W|r) Drunken Haze - [|cffffcc00Level 1|r],(|cffffcc00W|r) Drunken Haze - [|cffffcc00Level 2|r],(|cffffcc00W|r) Drunken Haze - [|cffffcc00Level 3|r],(|cffffcc00W|r) Drunken Haze - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Drunken Haze - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [acdb]
                  Tip=Drunken Brawler - [|cffffcc00Level 1|r],Drunken Brawler - [|cffffcc00Level 2|r],Drunken Brawler - [|cffffcc00Level 3|r],Drunken Brawler - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Drunken Brawler - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [acef]
                  Tip=(|cffffcc00R|r) Storm,(|cffffcc00R|r)  Earth,(|cffffcc00R|r)  And Fire - [|cffffcc00Level 1|r],(|cffffcc00R|r) Storm,(|cffffcc00R|r)  Earth,(|cffffcc00R|r)  And Fire - [|cffffcc00Level 2|r]
                  Researchtip=(|cffffcc00R|r) Learn Storm,Earth,And Fire - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [anhw]
                  Tip=(|cffffcc00Q|r) Healing Wave - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Healing Wave - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Healing Wave - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Healing Wave - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Healing Wave - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [anhx]
                  Tip=(|cffffcc00W|r) Hex - [|cffffcc00Level 1|r],(|cffffcc00W|r) Hex - [|cffffcc00Level 2|r],(|cffffcc00W|r) Hex - [|cffffcc00Level 3|r],(|cffffcc00W|r) Hex - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Hex - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [arsw]
                  Tip=(|cffffcc00E|r) Serpent Ward - [|cffffcc00Level 1|r],(|cffffcc00E|r) Serpent Ward - [|cffffcc00Level 2|r],(|cffffcc00E|r) Serpent Ward - [|cffffcc00Level 3|r],(|cffffcc00E|r) Serpent Ward - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Serpent Ward - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [aols]
                  Tip=(|cffffcc00R|r) Voodoo Spirits - [|cffffcc00Level 1|r],(|cffffcc00R|r) Voodoo Spirits - [|cffffcc00Level 2|r]
                  Researchtip=(|cffffcc00R|r) Learn Voodoo Spirits - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [aos2]
                  Tip=(|cffffcc00Q|r) Shockwave - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Shockwave - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Shockwave - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Shockwave - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Shockwave - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [aow2]
                  Tip=(|cffffcc00W|r) War Stomp - [|cffffcc00Level 1|r],(|cffffcc00W|r) War Stomp - [|cffffcc00Level 2|r],(|cffffcc00W|r) War Stomp - [|cffffcc00Level 3|r],(|cffffcc00W|r) War Stomp - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn War Stomp - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [aor2]
                  Tip=Endurance Aura - [|cffffcc00Level 1|r],Endurance Aura - [|cffffcc00Level 2|r],Endurance Aura - [|cffffcc00Level 3|r],Endurance Aura - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Endurance Aura - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [aor3]
                  Tip=Reincarnation - [|cffffcc00Level 1|r],Reincarnation - [|cffffcc00Level 2|r]
                  Researchtip=(|cffffcc00R|r) Learn Reincarnation - [|cffffcc00Level %d|r]
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [nngs]
                  Tip=(|cffffcc00A|r) Summon Naga Sea Witch
                  Revivetip=(|cffffcc00A|r) Revive Naga Sea Witch
                  Awakentip=(|cffffcc00A|r) Awaken Naga Sea Witch
                  Hotkey=A
                  Buttonpos=0,1

                  [nbrn]
                  Tip=(|cffffcc00S|r) Summon Dark Ranger
                  Revivetip=(|cffffcc00S|r) Revive Dark Ranger
                  Awakentip=(|cffffcc00S|r) Awaken Dark Ranger
                  Hotkey=S
                  Buttonpos=1,1

                  [npbm]
                  Tip=(|cffffcc00D|r) Summon Pandaren Brewmaster
                  Revivetip=(|cffffcc00D|r) Revive Pandaren Brewmaster
                  Awakentip=(|cffffcc00D|r) Awaken Pandaren Brewmaster
                  Hotkey=D
                  Buttonpos=2,1

                  [nfir]
                  Tip=(|cffffcc00F|r) Summon Firelord
                  Revivetip=(|cffffcc00F|r) Revive Firelord
                  Awakentip=(|cffffcc00F|r) Awaken Firelord
                  Hotkey=F
                  Buttonpos=3,1

                  [nplh]
                  Tip=(|cffffcc00Y|r) Summon Pit Lord
                  Revivetip=(|cffffcc00Y|r) Revive Pit Lord
                  Awakentip=(|cffffcc00Y|r) Awaken Pit Lord
                  Hotkey=Y
                  Buttonpos=0,2

                  [nbst]
                  Tip=(|cffffcc00X|r) Summon Beastmaster
                  Revivetip=(|cffffcc00X|r) Revive Beastmaster
                  Awakentip=(|cffffcc00X|r) Awaken Beastmaster
                  Hotkey=X
                  Buttonpos=1,2

                  [ntin]
                  Tip=(|cffffcc00C|r) Summon Goblin Tinker
                  Revivetip=(|cffffcc00C|r) Revive Goblin Tinker
                  Awakentip=(|cffffcc00C|r) Awaken Goblin Tinker
                  Hotkey=C

                  [nalc]
                  Tip=(|cffffcc00V|r) Summon Alchemist
                  Revivetip=(|cffffcc00V|r) Revive Alchemist
                  Awakentip=(|cffffcc00V|r) Awaken Alchemist
                  Hotkey=V
                  Buttonpos=3,2

                  [bspd]
                  Tip=(|cffffcc00Q|r) Purchase Boots of Speed
                  Hotkey=Q
                  Buttonpos=0,0

                  [prvt]
                  Tip=(|cffffcc00W|r) Purchase Periapt of Vitality
                  Hotkey=W
                  Buttonpos=1,0

                  [cnob]
                  Tip=(|cffffcc00R|r) Purchase Circlet of Nobility
                  Hotkey=R
                  Buttonpos=3,0

                  [spro]
                  Tip=(|cffffcc00A|r) Purchase Scroll of Protection
                  Hotkey=A
                  Buttonpos=0,1

                  [pinv]
                  Tip=(|cffffcc00S|r) Purchase Potion of Invisibility
                  Hotkey=S
                  Buttonpos=1,1

                  [stel]
                  Tip=(|cffffcc00F|r) Purchase Staff of Teleportation
                  Hotkey=F
                  Buttonpos=3,1

                  [tret]
                  Tip=(|cffffcc00Y|r) Purchase Tome of Retraining
                  Hotkey=Y
                  Buttonpos=0,2

                  [pnvl]
                  Tip=(|cffffcc00C|r) Purchase Potion of Lesser Invulnerability
                  Hotkey=C
                  Buttonpos=2,2

                  [andt]
                  Tip=(|cffffcc00R|r) Reveal
                  Hotkey=R
                  Buttonpos=3,0

                  [ngsp]
                  Tip=(|cffffcc00W|r) Hire Goblin Sapper
                  Hotkey=W
                  Buttonpos=1,0

                  [nzep]
                  Tip=(|cffffcc00E|r) Hire Goblin Zeppelin
                  Hotkey=E
                  Buttonpos=2,0

                  [ngir]
                  Tip=(|cffffcc00Q|r) Hire Goblin Shredder
                  Hotkey=Q
                  Buttonpos=0,0

                  [nbot]
                  Tip=(|cffffcc00Q|r) Hire Transport Ship
                  Hotkey=Q
                  Buttonpos=0,0

                  [nfsp]
                  Tip=(|cffffcc00Q|r) Hire Forest Troll Shadow Priest
                  Hotkey=Q
                  Buttonpos=0,0

                  [nftb]
                  Tip=(|cffffcc00W|r) Hire Forest Troll Berserker
                  Hotkey=W
                  Buttonpos=1,0

                  [ngrk]
                  Tip=(|cffffcc00E|r) Summon Mud Golem
                  Hotkey=E
                  Buttonpos=2,0

                  [nogm]
                  Tip=(|cffffcc00R|r) Hire Ogre Mauler
                  Hotkey=R
                  Buttonpos=3,0

                  [nkob]
                  Tip=(|cffffcc00W|r) Hire Kobold
                  Hotkey=W
                  Buttonpos=1,0

                  [nass]
                  Tip=(|cffffcc00Q|r) Hire Assassin
                  Hotkey=Q
                  Buttonpos=0,0

                  [nkog]
                  Tip=(|cffffcc00E|r) Hire Kobold Geomancer
                  Hotkey=E
                  Buttonpos=2,0

                  [nmrr]
                  Tip=(|cffffcc00R|r) Hire Murloc Huntsman
                  Hotkey=R
                  Buttonpos=3,0

                  [nmfs]
                  Tip=(|cffffcc00Q|r) Hire Murloc Flesheater
                  Hotkey=Q
                  Buttonpos=0,0

                  [nslf]
                  Tip=(|cffffcc00W|r) Summon Sludge Flinger
                  Hotkey=W
                  Buttonpos=1,0

                  [nstl]
                  Tip=(|cffffcc00E|r) Hire Satyr Soulstealer
                  Hotkey=E
                  Buttonpos=2,0

                  [nsts]
                  Tip=(|cffffcc00Q|r) Hire Satyr Shadowdancer
                  Hotkey=Q
                  Buttonpos=0,0

                  [nfrs]
                  Tip=(|cffffcc00E|r) Hire Furbolg Shaman
                  Hotkey=E
                  Buttonpos=2,0

                  [nthl]
                  Tip=(|cffffcc00W|r) Summon Thunder Lizzard
                  Hotkey=W
                  Buttonpos=1,0

                  [ngnb]
                  Tip=(|cffffcc00R|r) Hire Gnoll Brute
                  Hotkey=R
                  Buttonpos=3,0

                  [ngnw]
                  Tip=(|cffffcc00W|r) Hire Gnoll Warden
                  Hotkey=W
                  Buttonpos=1,0

                  [nomg]
                  Tip=(|cffffcc00Q|r) Hire Ogre Magi
                  Hotkey=Q
                  Buttonpos=0,0

                  [nitt]
                  Tip=(|cffffcc00Q|r) Hire Ice Troll Trapper
                  Hotkey=Q
                  Buttonpos=0,0

                  [nits]
                  Tip=(|cffffcc00W|r) Hire Ice Troll Berserker
                  Hotkey=W
                  Buttonpos=1,0

                  [ngnv]
                  Tip=(|cffffcc00R|r) Hire Gnoll Overseer
                  Hotkey=R
                  Buttonpos=3,0

                  [nrog]
                  Tip=(|cffffcc00W|r) Hire Rogue
                  Hotkey=W
                  Buttonpos=1,0

                  [nfsh]
                  Tip=(|cffffcc00R|r) Hire Forest Troll Shadow Priest
                  Hotkey=R
                  Buttonpos=3,0

                  [ncen]
                  Tip=(|cffffcc00Q|r) Hire Centaur Outrunner
                  Hotkey=Q
                  Buttonpos=0,0

                  [nhrr]
                  Tip=(|cffffcc00W|r) Hire Harpy Rogue
                  Hotkey=W
                  Buttonpos=1,0

                  [nhrw]
                  Tip=(|cffffcc00E|r) Hire Harpy Windwitch
                  Hotkey=E
                  Buttonpos=2,0

                  [nrzm]
                  Tip=(|cffffcc00R|r) Hire Razormane Medicine Man
                  Hotkey=R
                  Buttonpos=3,0

                  [nnwa]
                  Tip=(|cffffcc00Q|r) Summon Nerubian Warrior
                  Hotkey=Q
                  Buttonpos=0,0

                  [nnwl]
                  Tip=(|cffffcc00E|r) Summon Nerubian Webspinner
                  Hotkey=E
                  Buttonpos=2,0

                  [nrvs]
                  Tip=(|cffffcc00R|r) Summon Frost Revenant
                  Hotkey=R
                  Buttonpos=3,0

                  [nskf]
                  Tip=(|cffffcc00Q|r) Hire Burning Archer
                  Hotkey=Q
                  Buttonpos=0,0

                  [nowb]
                  Tip=(|cffffcc00W|r) Summon Wildkin
                  Hotkey=W
                  Buttonpos=1,0

                  [ntrt]
                  Tip=(|cffffcc00Q|r) Hire Giant See Turtle
                  Hotkey=Q
                  Buttonpos=0,0

                  [nlsn]
                  Tip=(|cffffcc00W|r) Hire Makrura Snipper
                  Hotkey=W
                  Buttonpos=1,0

                  [nmsn]
                  Tip=(|cffffcc00E|r) Hire Mur'gul Snarecaster
                  Hotkey=E
                  Buttonpos=2,0

                  [nlds]
                  Tip=(|cffffcc00R|r) Hire MaKrura Deepseer
                  Hotkey=R
                  Buttonpos=3,0

                  [nanm]
                  Tip=(|cffffcc00Q|r) Hire Barbed Arachmatid
                  Hotkey=Q
                  Buttonpos=0,0

                  [nbdm]
                  Tip=(|cffffcc00W|r) Hire Blue DragonSpawn Meddler
                  Hotkey=W
                  Buttonpos=1,0

                  [nfps]
                  Tip=(|cffffcc00E|r) Hire Polar Furbolg Shaman
                  Hotkey=E
                  Buttonpos=2,0

                  [nmgw]
                  Tip=(|cffffcc00R|r) Hire Magnataur Warrior
                  Hotkey=R
                  Buttonpos=3,0

                  [npfl]
                  Tip=(|cffffcc00Q|r) Summon Fel Beast
                  Hotkey=Q
                  Buttonpos=0,0

                  [ndrm]
                  Tip=(|cffffcc00W|r) Hire Draenei Disciple
                  Hotkey=W
                  Buttonpos=1,0

                  [nvdw]
                  Tip=(|cffffcc00E|r) Hire Voidwalker
                  Hotkey=E
                  Buttonpos=2,0

                  [ndrd]
                  Tip=(|cffffcc00R|r) Hire Draenei Darkslayer
                  Hotkey=R
                  Buttonpos=3,0

                  [nrdk]
                  Tip=(|cffffcc00Q|r) Summon Red Dragon Whelp
                  Hotkey=Q
                  Buttonpos=0,0

                  [nrdr]
                  Tip=(|cffffcc00W|r) Summon Red Drake
                  Hotkey=W
                  Buttonpos=1,0

                  [nrwm]
                  Tip=(|cffffcc00E|r) Summon Red Dragon
                  Hotkey=E
                  Buttonpos=2,0

                  [nbdr]
                  Tip=(|cffffcc00Q|r) Summon Black Dragon Whelp
                  Hotkey=Q
                  Buttonpos=0,0

                  [nbdk]
                  Tip=(|cffffcc00W|r) Summon Black Drake
                  Hotkey=W
                  Buttonpos=1,0

                  [nbwm]
                  Tip=(|cffffcc00E|r) Summon Black Dragon
                  Hotkey=E
                  Buttonpos=2,0

                  [nadw]
                  Tip=(|cffffcc00Q|r) Summon Blue Dragon Whelp
                  Hotkey=Q
                  Buttonpos=0,0

                  [nadk]
                  Tip=(|cffffcc00W|r) Summon Blue Drake
                  Hotkey=W
                  Buttonpos=1,0

                  [nadr]
                  Tip=(|cffffcc00E|r) Summon Blue Dragon
                  Hotkey=E
                  Buttonpos=2,0

                  [nbzw]
                  Tip=(|cffffcc00Q|r) Summon Bronze Dragon Whelp
                  Hotkey=Q
                  Buttonpos=0,0

                  [nbzk]
                  Tip=(|cffffcc00W|r) Summon Bronze Drake
                  Hotkey=W
                  Buttonpos=1,0

                  [nbzd]
                  Tip=(|cffffcc00E|r) Summon Bronze Dragon
                  Hotkey=E
                  Buttonpos=2,0

                  [ngrw]
                  Tip=(|cffffcc00Q|r) Summon Green Dragon Whelp
                  Hotkey=Q
                  Buttonpos=0,0

                  [ngdk]
                  Tip=(|cffffcc00W|r) Summon Green Drake
                  Hotkey=W
                  Buttonpos=1,0

                  [ngrd]
                  Tip=(|cffffcc00E|r) Summon Green Dragon
                  Hotkey=E
                  Buttonpos=2,0

                  [nnht]
                  Tip=(|cffffcc00Q|r) Summon Nether Dragon Hatchling
                  Hotkey=Q
                  Buttonpos=0,0

                  [nndk]
                  Tip=(|cffffcc00W|r) Summon Nether Drake
                  Hotkey=W
                  Buttonpos=1,0

                  [nndr]
                  Tip=(|cffffcc00E|r) Summon Nether Dragon
                  Hotkey=E
                  Buttonpos=2,0

                  [aloa]
                  Tip=(|cffffcc00Q|r) Load
                  Hotkey=Q
                  Buttonpos=0,0

                  [adro]
                  Tip=(|cffffcc00W|r) Unload All
                  Hotkey=W
                  Buttonpos=1,0

                  [asds]
                  Tip=(|cffffcc00Q|r) Kaboom!
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [ahr3]
                  Tip=(|cffffcc00F|r) Gather
                  UnTip=(|cffffcc00F|r) Return Resources
                  Hotkey=F
                  Unhotkey=F
                  Buttonpos=3,1
                  Unbuttonpos=3,1

                  [acsf]
                  Tip=(|cffffcc00W|r) Feral Spirit
                  Hotkey=W
                  Buttonpos=1,0

                  [ANsg]
                  Tip=(|cffffcc00Q|r) Summon Bear - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Summon Bear - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Summon Bear - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Q|r) Learn Summon Bear - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [ANsq]
                  Tip=(|cffffcc00W|r) Quilbeast - [|cffffcc00Level 1|r],(|cffffcc00W|r) Quilbeast - [|cffffcc00Level 2|r],(|cffffcc00W|r) Quilbeast - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00W|r) Learn Quilbeast - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [ANsw]
                  Tip=(|cffffcc00E|r) Summon Hawk - [|cffffcc00Level 1|r],(|cffffcc00E|r) Summon Hawk - [|cffffcc00Level 2|r],(|cffffcc00E|r) Summon Hawk - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00E|r) Learn Summon Hawk - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [ANst]
                  Tip=(|cffffcc00R|r) Stampede
                  Researchtip=(|cffffcc00R|r) Learn Stampede
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [ansi]
                  Tip=(|cffffcc00Q|r) Silence - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Silence - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Silence - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Q|r) Learn Silence - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [anba]
                  Tip=(|cffffcc00W|r) Black Arrow - [|cffffcc00Level 1|r],(|cffffcc00W|r) Black Arrow - [|cffffcc00Level 2|r],(|cffffcc00W|r) Black Arrow - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00W|r) Learn Black Arrow - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,0
                  Researchbuttonpos=1,0

                  [andr]
                  Tip=(|cffffcc00E|r) Life Drain - [|cffffcc00Level 1|r],(|cffffcc00E|r) Life Drain - [|cffffcc00Level 2|r],(|cffffcc00E|r) Life Drain - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00E|r) Learn Life Drain - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [anch]
                  Tip=(|cffffcc00R|r) Charm
                  Researchtip=(|cffffcc00R|r) Learn Charm
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [anfl]
                  Tip=(|cffffcc00Q|r) Forked Lightning - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Forked Lightning - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Forked Lightning - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Q|r) Learn Forked Lightning - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [anfa]
                  Tip=(|cffffcc00W|r) Frost Arrows - [|cffffcc00Level 1|r],(|cffffcc00W|r) Frost Arrows - [|cffffcc00Level 2|r],(|cffffcc00W|r) Frost Arrows - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00W|r) Learn Frost Arrows - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,0
                  Researchbuttonpos=1,0

                  [anms]
                  Tip=(|cffffcc00E|r) Activate Mana Shield - [|cffffcc00Level 1|r],(|cffffcc00E|r) Activate Mana Shield - [|cffffcc00Level 2|r],(|cffffcc00E|r) Activate Mana Shield - [|cffffcc00Level 3|r]
                  UnTip=(|cffffcc00E|r) Deactivate Mana Shield
                  Researchtip=(|cffffcc00E|r) Learn Activate Mana Shield - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Unhotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Unbuttonpos=2,0
                  Researchbuttonpos=2,0

                  [anto]
                  Tip=(|cffffcc00R|r) Tornado
                  Researchtip=(|cffffcc00R|r) Learn Tornado
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [anbf]
                  Tip=(|cffffcc00Q|r) Breath of Fire - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Breath of Fire - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Breath of Fire - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Q|r) Learn Breath of Fire - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [andh]
                  Tip=(|cffffcc00W|r) Drunken Haze - [|cffffcc00Level 1|r],(|cffffcc00W|r) Drunken Haze - [|cffffcc00Level 2|r],(|cffffcc00W|r) Drunken Haze - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00W|r) Learn Drunken Haze - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [andb]
                  Tip=Drunken Brawler - [|cffffcc00Level 1|r],Drunken Brawler - [|cffffcc00Level 2|r],Drunken Brawler - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00E|r) Learn Drunken Brawler - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [anef]
                  Tip=(|cffffcc00R|r) Storm,Earth,And Fire
                  Researchtip=(|cffffcc00R|r) Learn Storm,Earth,And Fire
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [anrf]
                  Tip=(|cffffcc00Q|r) Rain of Fire - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Rain of Fire - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Rain of Fire - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Q|r) Learn Rain of Fire - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [anht]
                  Tip=(|cffffcc00W|r) Howl of Terror - [|cffffcc00Level 1|r],(|cffffcc00W|r) Howl of Terror - [|cffffcc00Level 2|r],(|cffffcc00W|r) Howl of Terror - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00W|r) Learn Howl of Terror - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [anca]
                  Tip=Cleaving Attack - [|cffffcc00Level 1|r],Cleaving Attack - [|cffffcc00Level 2|r],Cleaving Attack - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00E|r) Learn Cleaving Attack - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [ando]
                  Tip=(|cffffcc00R|r) Doom
                  Researchtip=(|cffffcc00R|r) Learn Doom
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [anso]
                  Tip=(|cffffcc00Q|r) Soul Burn - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Soul Burn - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Soul Burn - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Q|r) Learn Soul Burn - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [anlm]
                  Tip=(|cffffcc00W|r) Summon Lava Spawn - [|cffffcc00Level 1|r],(|cffffcc00W|r) Summon Lava Spawn - [|cffffcc00Level 2|r],(|cffffcc00W|r) Summon Lava Spawn - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00W|r) Learn Summon Lava Spawn - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [ania]
                  Tip=(|cffffcc00E|r) Incinerate - [|cffffcc00Level 1|r],(|cffffcc00E|r) Incinerate - [|cffffcc00Level 2|r],(|cffffcc00E|r) Incinerate - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00E|r) Learn Incinerate - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Unbuttonpos=2,0
                  Researchbuttonpos=2,0

                  [anvc]
                  Tip=(|cffffcc00R|r) Volcano
                  Researchtip=(|cffffcc00R|r) Learn Volcano
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [anhs]
                  Tip=(|cffffcc00Q|r) Healing Spray - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Healing Spray - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Healing Spray - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Q|r) Learn Healing Spray - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [anab]
                  Tip=(|cffffcc00E|r) Acid Bomb - [|cffffcc00Level 1|r],(|cffffcc00E|r) Acid Bomb - [|cffffcc00Level 2|r],(|cffffcc00E|r) Acid Bomb - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00E|r) Learn Acid Bomb - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [ancr]
                  Tip=(|cffffcc00W|r) Chemical Rage - [|cffffcc00Level 1|r],(|cffffcc00W|r) Chemical Rage - [|cffffcc00Level 2|r],(|cffffcc00W|r) Chemical Rage - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00W|r) Learn Chemical Rage - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [antm]
                  Tip=(|cffffcc00R|r) Transmute
                  Researchtip=(|cffffcc00R|r) Learn Transmute
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [ansy]
                  Tip=(|cffffcc00Q|r) Pocket Factory - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Pocket Factory - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Pocket Factory - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Q|r) Learn Pocket Factory - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [ans1]
                  Tip=(|cffffcc00Q|r) Pocket Factory - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Pocket Factory - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Pocket Factory - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Q|r) Learn Pocket Factory - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [ans2]
                  Tip=(|cffffcc00Q|r) Pocket Factory - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Pocket Factory - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Pocket Factory - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Q|r) Learn Pocket Factory - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [ans3]
                  Tip=(|cffffcc00Q|r) Pocket Factory - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Pocket Factory - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Pocket Factory - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Q|r) Learn Pocket Factory - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [ancs]
                  Tip=(|cffffcc00W|r) Cluster Rockets - [|cffffcc00Level 1|r],(|cffffcc00W|r) Cluster Rockets - [|cffffcc00Level 2|r],(|cffffcc00W|r) Cluster Rockets - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00W|r) Learn Cluster Rockets - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [anc1]
                  Tip=(|cffffcc00W|r) Cluster Rockets - [|cffffcc00Level 1|r],(|cffffcc00W|r) Cluster Rockets - [|cffffcc00Level 2|r],(|cffffcc00W|r) Cluster Rockets - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00W|r) Learn Cluster Rockets - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [anc2]
                  Tip=(|cffffcc00W|r) Cluster Rockets - [|cffffcc00Level 1|r],(|cffffcc00W|r) Cluster Rockets - [|cffffcc00Level 2|r],(|cffffcc00W|r) Cluster Rockets - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00W|r) Learn Cluster Rockets - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [anc3]
                  Tip=(|cffffcc00W|r) Cluster Rockets - [|cffffcc00Level 1|r],(|cffffcc00W|r) Cluster Rockets - [|cffffcc00Level 2|r],(|cffffcc00W|r) Cluster Rockets - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00W|r) Learn Cluster Rockets - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [aneg]
                  Tip=Engineering Upgrade - [|cffffcc00Level 1|r],Engineering Upgrade - [|cffffcc00Level 2|r],Engineering Upgrade - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00E|r) Learn Engineering Upgrade - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [anrg]
                  Tip=(|cffffcc00R|r) Robo-Goblin
                  UnTip=(|cffffcc00R|r) Revert to Tinker Form
                  Researchtip=(|cffffcc00R|r) Learn Robo-Goblin
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Unbuttonpos=3,0
                  Researchbuttonpos=3,0

                  [ang1]
                  Tip=(|cffffcc00R|r) Robo-Goblin
                  UnTip=(|cffffcc00R|r) Revert to Tinker Form
                  Researchtip=(|cffffcc00R|r) Learn Robo-Goblin
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Unbuttonpos=3,0
                  Researchbuttonpos=3,0

                  [ang2]
                  Tip=(|cffffcc00R|r) Robo-Goblin
                  UnTip=(|cffffcc00R|r) Revert to Tinker Form
                  Researchtip=(|cffffcc00R|r) Learn Robo-Goblin
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Unbuttonpos=3,0
                  Researchbuttonpos=3,0

                  [ang3]
                  Tip=(|cffffcc00R|r) Robo-Goblin
                  UnTip=(|cffffcc00R|r) Revert to Tinker Form
                  Researchtip=(|cffffcc00R|r) Learn Robo-Goblin
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Unbuttonpos=3,0
                  Researchbuttonpos=3,0

                  [ande]
                  Tip=Demolish
                  Buttonpos=1,2

                  [and1]
                  Tip=Demolish - Upgrade Level 1
                  Buttonpos=1,2

                  [and2]
                  Tip=Demolish - Upgrade Level 2
                  Buttonpos=1,2

                  [and3]
                  Tip=Demolish - Upgrade Level 3
                  Buttonpos=1,2

                  [anwk]
                  Tip=(|cffffcc00R|r) Wind Walk
                  Hotkey=R
                  Buttonpos=3,0

                  [anta]
                  Tip=(|cffffcc00Q|r) Taunt
                  Hotkey=Q
                  Buttonpos=0,0

                  [apig]
                  Tip=Permanent Immolation
                  Buttonpos=0,0

                  [acrf]
                  Tip=(|cffffcc00R|r) Rain of Fire
                  Hotkey=R
                  Buttonpos=3,0

                  [anbl]
                  Tip=(|cffffcc00Q|r) Blink
                  Hotkey=Q
                  Buttonpos=0,0

                  [afzy]
                  Tip=(|cffffcc00Q|r) Frenzy
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [antr]
                  Tip=True Sight
                  Buttonpos=0,0

                  [asdg]
                  Tip=(|cffffcc00Q|r) Kaboom!
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [asd1]
                  Tip=(|cffffcc00Q|r) Kaboom!
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [asd2]
                  Tip=(|cffffcc00Q|r) Kaboom!
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [asd3]
                  Tip=(|cffffcc00Q|r) Kaboom!
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [acbk]
                  Tip=(|cffffcc00Q|r) Black Arrow
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [acbb]
                  Tip=(|cffffcc00Q|r) Bloodlust
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [acbl]
                  Tip=(|cffffcc00W|r) Bloodlust
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,0

                  [acbc]
                  Tip=(|cffffcc00W|r) Breath of Fire
                  Hotkey=W
                  Buttonpos=1,0

                  [acbz]
                  Tip=(|cffffcc00Q|r) Blizzard
                  Hotkey=Q
                  Buttonpos=0,0

                  [accn]
                  Tip=(|cffffcc00Q|r) Cannibalize
                  Hotkey=Q
                  Buttonpos=0,0

                  [accv]
                  Tip=(|cffffcc00Q|r) Crushing Wave
                  Hotkey=Q
                  Buttonpos=0,0

                  [accw]
                  Tip=(|cffffcc00Q|r) Cold Arrows
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [accs]
                  Tip=(|cffffcc00Q|r) Curse
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [acdc]
                  Tip=(|cffffcc00Q|r) Death Coil
                  Hotkey=Q
                  Buttonpos=0,0

                  [acdv]
                  Tip=(|cffffcc00Q|r) Devour
                  Hotkey=Q
                  Buttonpos=0,0

                  [acen]
                  Tip=(|cffffcc00Q|r) Ensnare
                  Hotkey=Q
                  Buttonpos=0,0

                  [aenr]
                  Tip=(|cffffcc00Q|r) Entangling Roots
                  Hotkey=Q
                  Buttonpos=0,0

                  [aenw]
                  Tip=(|cffffcc00Q|r) Entangling Roots
                  Hotkey=Q
                  Buttonpos=0,0

                  [acff]
                  Tip=(|cffffcc00Q|r) Faerie Fire
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [afa2]
                  Tip=(|cffffcc00Q|r) Faerie Fire
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [acfb]
                  Tip=(|cffffcc00Q|r) Firebolt
                  Hotkey=Q
                  Buttonpos=0,0

                  [acfd]
                  Tip=(|cffffcc00W|r) Finger of Pain
                  Hotkey=W
                  Buttonpos=1,0

                  [acfn]
                  Tip=(|cffffcc00Q|r) Frost Nova
                  Hotkey=Q
                  Buttonpos=0,0

                  [anh2]
                  Tip=(|cffffcc00Q|r) Heal
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [achw]
                  Tip=(|cffffcc00Q|r) Healing Ward
                  Hotkey=Q
                  Buttonpos=0,0

                  [achv]
                  Tip=(|cffffcc00Q|r) Healing Wave
                  Hotkey=Q
                  Buttonpos=0,0

                  [acht]
                  Tip=(|cffffcc00Q|r) Howl of Terror
                  Hotkey=Q
                  Buttonpos=0,0

                  [actb]
                  Tip=(|cffffcc00W|r) Hurl Boulder
                  Hotkey=W
                  Buttonpos=1,0

                  [acbf]
                  Tip=(|cffffcc00Q|r) Breath of Frost
                  Hotkey=Q
                  Buttonpos=0,0

                  [acdr]
                  Tip=(|cffffcc00Q|r) Life Drain
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,2

                  [ambb]
                  Tip=(|cffffcc00Q|r) Mana Burn
                  Hotkey=Q
                  Buttonpos=0,0

                  [ambd]
                  Tip=(|cffffcc00Q|r) Mana Burn
                  Hotkey=Q
                  Buttonpos=0,0

                  [acmo]
                  Tip=(|cffffcc00Q|r) Monsoon
                  Hotkey=Q
                  Buttonpos=0,0

                  [acpa]
                  Tip=(|cffffcc00Q|r) Parasite
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [acpu]
                  Tip=(|cffffcc00Q|r) Purge
                  Hotkey=Q
                  Buttonpos=0,0

                  [acrd]
                  Tip=(|cffffcc00W|r) Raise Dead
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,0

                  [acro]
                  Tip=(|cffffcc00Q|r) Roar
                  Hotkey=Q
                  Buttonpos=0,0

                  [acr2]
                  Tip=(|cffffcc00Q|r) Rejuvenation
                  Hotkey=Q
                  Buttonpos=0,0

                  [acsi]
                  Tip=(|cffffcc00Q|r) Silence
                  Hotkey=Q
                  Buttonpos=0,0

                  [acs2]
                  Tip=(|cffffcc00Q|r) Slow
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [acdm]
                  Tip=(|cffffcc00W|r) Abolish Magic
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,0

                  [acca]
                  Tip=(|cffffcc00Q|r) Carrion Swarm
                  Hotkey=Q
                  Buttonpos=0,0

                  [accb]
                  Tip=(|cffffcc00W|r) Frost Bolt
                  Hotkey=W
                  Buttonpos=1,0

                  [acce]
                  Tip=Cleaving Attack
                  Buttonpos=1,0

                  [accy]
                  Tip=(|cffffcc00Q|r) Cyclone
                  Hotkey=Q
                  Buttonpos=0,0

                  [acde]
                  Tip=(|cffffcc00W|r) Devour Magic
                  Hotkey=W
                  Buttonpos=1,0

                  [aap3]
                  Tip=Disease Cloud
                  Buttonpos=1,0

                  [acds]
                  Tip=(|cffffcc00W|r) Activate Divine Shield
                  Hotkey=W
                  Buttonpos=1,0

                  [achx]
                  Tip=(|cffffcc00W|r) Hex
                  Hotkey=W
                  Buttonpos=1,0

                  [acs9]
                  Tip=(|cffffcc00W|r) Feral Spirit
                  Hotkey=W
                  Buttonpos=1,0

                  [acsh]
                  Tip=(|cffffcc00Q|r) Shockwave
                  Hotkey=Q
                  Buttonpos=0,0

                  [anfb]
                  Tip=(|cffffcc00W|r) Firebolt
                  Hotkey=W
                  Buttonpos=1,0

                  [acfl]
                  Tip=(|cffffcc00Q|r) Forked Lightning
                  Hotkey=Q
                  Buttonpos=0,0

                  [anh1]
                  Tip=(|cffffcc00Q|r) Heal
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [acim]
                  Tip=(|cffffcc00W|r) Activate Immolation
                  UnTip=(|cffffcc00W|r) Deactivate Immolation
                  Hotkey=W
                  Unhotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,0

                  [acls]
                  Tip=(|cffffcc00W|r) Lightning Shield
                  Hotkey=W
                  Buttonpos=1,0

                  [acmf]
                  Tip=(|cffffcc00Q|r) Activate Mana Shield
                  UnTip=(|cffffcc00Q|r) Deactivate Mana Shield
                  Hotkey=Q
                  Unhotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [acrj]
                  Tip=(|cffffcc00W|r) Rejuvenation
                  Hotkey=W
                  Buttonpos=1,0

                  [acsa]
                  Tip=(|cffffcc00W|r) Searing Arrows
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,0

                  [actc]
                  Tip=(|cffffcc00E|r) Slam
                  Hotkey=E
                  Buttonpos=2,0

                  [acsl]
                  Tip=(|cffffcc00Q|r) Sleep
                  Hotkey=Q
                  Buttonpos=0,0

                  [acsw]
                  Tip=(|cffffcc00Q|r) Slow
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [awrs]
                  Tip=(|cffffcc00Q|r) War Stomp
                  Hotkey=Q
                  Buttonpos=0,0

                  [acwb]
                  Tip=(|cffffcc00Q|r) Web
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [ache]
                  Tip=(|cffffcc00W|r) Cast Ray of Disruption
                  Hotkey=W
                  Buttonpos=1,0

                  [acwe]
                  Tip=(|cffffcc00E|r) Summon Sea Elemental
                  Hotkey=E
                  Buttonpos=2,0

                  [acbh]
                  Tip=Bash
                  Buttonpos=0,0

                  [acba]
                  Tip=Brilliance Aura
                  Buttonpos=2,0

                  [accl]
                  Tip=(|cffffcc00E|r) Chain Lightning
                  Hotkey=E
                  Buttonpos=2,0

                  [accr]
                  Tip=(|cffffcc00W|r) Cripple
                  Hotkey=W
                  Buttonpos=1,0

                  [acct]
                  Tip=Critical Strike
                  Buttonpos=0,0

                  [acav]
                  Tip=Devotion Aura
                  Buttonpos=2,0

                  [scae]
                  Tip=Endurance Aura
                  Buttonpos=1,0

                  [acev]
                  Tip=Evasion
                  Buttonpos=2,0

                  [acif]
                  Tip=(|cffffcc00E|r) Inner Fire
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=E
                  Buttonpos=2,0
                  Unbuttonpos=2,0

                  [acps]
                  Tip=(|cffffcc00E|r) Possession
                  Hotkey=E
                  Buttonpos=2,0

                  [acss]
                  Tip=(|cffffcc00E|r) Shadow Strike
                  Hotkey=E
                  Buttonpos=2,0

                  [ant2]
                  Tip=Spiked Shell
                  Buttonpos=2,0

                  [aslp]
                  Tip=(|cffffcc00E|r) Summon Prawns
                  Hotkey=E
                  Buttonpos=2,0

                  [acah]
                  Tip=Thorns Aura
                  Buttonpos=2,0

                  [acat]
                  Tip=Trueshot Aura
                  Buttonpos=2,0

                  [acua]
                  Tip=Unholy Aura
                  Buttonpos=1,0

                  [acvp]
                  Tip=Vampiric Aura
                  Buttonpos=2,0

                  [awrh]
                  Tip=(|cffffcc00E|r) War Stomp
                  Hotkey=E
                  Buttonpos=2,0

                  [acad]
                  Tip=(|cffffcc00R|r) Animate Dead
                  Hotkey=R
                  Buttonpos=3,0

                  [acch]
                  Tip=(|cffffcc00R|r) Charm
                  Hotkey=R
                  Buttonpos=3,0

                  [acpy]
                  Tip=(|cffffcc00R|r) Polymorph
                  Hotkey=R
                  Buttonpos=3,0

                  [acrn]
                  Tip=Reincarnation
                  Buttonpos=3,0

                  [anin]
                  Tip=(|cffffcc00R|r) Inferno
                  Hotkey=R
                  Buttonpos=3,0

                  [anbh]
                  Tip=Bash
                  Buttonpos=3,0

                  [acvs]
                  Tip=Envenomed Weapons
                  Buttonpos=0,0

                  [acpv]
                  Tip=Pulverize
                  Buttonpos=3,0

                  [H06s]
                  Tip=Admiral
                  Buttonpos=0,0

                  [H00d]
                  Tip=Beastmaster
                  Buttonpos=1,0

                  [H000]
                  Tip=Centaur Warchief
                  Buttonpos=2,0

                  [N01i]
                  Tip=Alchemist
                  Buttonpos=3,2

                  [H001]
                  Tip=Rogue Knight
                  Buttonpos=1,1

                  [O015]
                  Tip=Tauren Chieftain
                  Buttonpos=1,2

                  [o01f]
                  Tip=Guardian Wisp
                  Buttonpos=3,0

                  [Harf]
                  Tip=Omniknight
                  Buttonpos=3,1

                  [H00t]
                  Tip=Clockwork Goblin
                  Buttonpos=0,0

                  [E02F]
                  Tip=Phoenix
                  Buttonpos=0,1

                  [Hlgr]
                  Tip=Dragon Knight
                  Buttonpos=1,0

                  [E02I]
                  Tip=Tuskarr
                  Buttonpos=1,1

                  [H00q]
                  Tip=Sacred Warrior
                  Buttonpos=2,0

                  [E02K]
                  Tip=Legion Commander
                  Buttonpos=2,1

                  [H008]
                  Tip=Bristleback
                  Buttonpos=3,0

                  [E032]
                  Tip=Goblin Shredder
                  Buttonpos=3,1

                  [Opgh]
                  Tip=Axe
                  Buttonpos=0,0

                  [U00a]
                  Tip=Chaos Knight
                  Buttonpos=1,0

                  [U008]
                  Tip=Lycanthrope
                  Buttonpos=1,1

                  [Uc42]
                  Tip=Doom Bringer
                  Buttonpos=2,0

                  [Uc91]
                  Tip=Slithereen Guard
                  Buttonpos=2,2

                  [U00c]
                  Tip=Lifestealer
                  Buttonpos=3,0

                  [N00r]
                  Tip=Pit Lord
                  Buttonpos=3,1

                  [H00r]
                  Tip=Unydying
                  Buttonpos=3,2

                  [U00f]
                  Tip=Butcher
                  Buttonpos=0,1

                  [Nc00]
                  Tip=Skeleton King
                  Buttonpos=2,1

                  [Uc11]
                  Tip=Magnataur
                  Buttonpos=1,0

                  [O00j]
                  Tip=Spiritbreaker
                  Buttonpos=2,0

                  [U00k]
                  Tip=Sand King
                  Buttonpos=3,0

                  [E005]
                  Tip=Moon Rider
                  Buttonpos=0,1

                  [Usyl]
                  Tip=Dwarven Sniper
                  Buttonpos=1,0

                  [O00p]
                  Tip=Morphling
                  Buttonpos=1,1

                  [Hc92]
                  Tip=Stealth Assassin
                  Buttonpos=1,2

                  [Nbbc]
                  Tip=Juggernaut
                  Buttonpos=2,0

                  [Hc49]
                  Tip=Naga Siren
                  Buttonpos=2,1

                  [N016]
                  Tip=Troll Warlord
                  Buttonpos=2,2

                  [N01o]
                  Tip=Lone Druid
                  Buttonpos=3,0

                  [Ogrh]
                  Tip=Phantom Lancer
                  Buttonpos=3,1

                  [e02n]
                  Tip=Gyrocopter
                  Buttonpos=3,2

                  [N01v]
                  Tip=Priestess of the Moon
                  Buttonpos=0,0

                  [Naka]
                  Tip=Bounty Hunter
                  Buttonpos=0,1

                  [E01y]
                  Tip=Templar Assassin
                  Buttonpos=1,0

                  [N0M0]
                  Tip=Ember Spirit
                  Buttonpos=1,1

                  [Huth]
                  Tip=Ursa Warrior
                  Buttonpos=2,0

                  [Hvwd]
                  Tip=Vengeful Spirit
                  Buttonpos=3,0

                  [Hvsh]
                  Tip=Bloodseeker
                  Buttonpos=0,0

                  [E01b]
                  Tip=Spectre
                  Buttonpos=0,2

                  [E004]
                  Tip=Bone Fletcher
                  Buttonpos=1,0

                  [Ec57]
                  Tip=Venomancer
                  Buttonpos=1,2

                  [U006]
                  Tip=Broodmother
                  Buttonpos=2,0

                  [Nfir]
                  Tip=Firelord
                  Buttonpos=3,1

                  [Ec77]
                  Tip=Netherdrake
                  Buttonpos=2,2

                  [U000]
                  Tip=Nerubian Assassin
                  Buttonpos=3,0

                  [Eevi]
                  Tip=Soul Keeper
                  Buttonpos=3,1

                  [H00i]
                  Tip=Geomancer
                  Buttonpos=3,2

                  [Ubal]
                  Tip=Nerubian Weaver
                  Buttonpos=1,1

                  [E002]
                  Tip=Lightning Revenant
                  Buttonpos=0,0

                  [N0MK]
                  Tip=Arc Warden
                  Buttonpos=0,1

                  [h071]
                  Tip=Murloc Nightcrawler
                  Buttonpos=1,0

                  [Ec45]
                  Tip=Faceless Void
                  Buttonpos=2,0

                  [H00v]
                  Tip=Gorgon
                  Buttonpos=3,0

                  [Hjai]
                  Tip=Crystal Maiden
                  Buttonpos=0,0

                  [H004]
                  Tip=Slayer
                  Buttonpos=0,2

                  [Hmbr]
                  Tip=Lord of Olympia
                  Buttonpos=1,1

                  [H00s]
                  Tip=Storm Spirit
                  Buttonpos=1,2

                  [N00b]
                  Tip=Faerie Dragon
                  Buttonpos=2,0

                  [Emns]
                  Tip=Prophet
                  Buttonpos=2,1

                  [H00a]
                  Tip=Holy Knight
                  Buttonpos=3,0

                  [N01a]
                  Tip=Silencer
                  Buttonpos=3,1

                  [e02j]
                  Tip=Thrall
                  Buttonpos=3,2

                  [N0eg]
                  Tip=Wind Runner
                  Buttonpos=1,0

                  [Orkn]
                  Tip=Shadow Shaman
                  Buttonpos=0,1

                  [H00k]
                  Tip=Goblin Techies
                  Buttonpos=1,0

                  [E02X]
                  Tip=Grand Magus
                  Buttonpos=1,1

                  [E00p]
                  Tip=Twin Head Dragon
                  Buttonpos=2,0

                  [H0Do]
                  Tip=Skywrath Mage
                  Buttonpos=2,1

                  [Ntin]
                  Tip=Tinker
                  Buttonpos=2,2

                  [U00p]
                  Tip=Obsidian Destroyer
                  Buttonpos=0,2

                  [H00n]
                  Tip=Dark Seer
                  Buttonpos=1,0

                  [Uc01]
                  Tip=Queen of Pain
                  Buttonpos=1,2

                  [Uc76]
                  Tip=Death Prophet
                  Buttonpos=2,0

                  [U00e]
                  Tip=Necrolyte
                  Buttonpos=2,1

                  [Uc18]
                  Tip=Demon Witch
                  Buttonpos=3,0

                  [H00h]
                  Tip=Oblivion
                  Buttonpos=3,1

                  [e02h]
                  Tip=Shadow Demon
                  Buttonpos=3,2

                  [Uktl]
                  Tip=Enigma
                  Buttonpos=0,0

                  [E01c]
                  Tip=Warlock
                  Buttonpos=1,1

                  [O016]
                  Tip=Batrider
                  Buttonpos=0,0

                  [N01w]
                  Tip=Shadow Priest
                  Buttonpos=1,0

                  [E01a]
                  Tip=Witch Doctor
                  Buttonpos=1,1

                  [H00u]
                  Tip=Invoker
                  Buttonpos=2,0

                  [n0hp]
                  Tip=Ancient Apparition
                  Buttonpos=2,1

                  [Uc60]
                  Tip=Necro´lic
                  Buttonpos=3,0

                  [N0M7]
                  Tip=Winter Wyvern
                  Buttonpos=3,1

                  [h03S]
                  Tip=(|cffffcc00Q|r) Assault Cuirass
                  Hotkey=Q
                  Buttonpos=0,0

                  [h03W]
                  Tip=(|cffffcc00A|r) Shiva's Guard
                  Hotkey=A
                  Buttonpos=0,1

                  [h02T]
                  Tip=Blade Mail
                  Buttonpos=0,2

                  [h03G]
                  Tip=(|cffffcc00W|r) Heart of Tarrasque
                  Hotkey=W
                  Buttonpos=1,0

                  [h03T]
                  Tip=Bloodstone
                  Buttonpos=1,1

                  [h02Z]
                  Tip=Soul Booster
                  Buttonpos=1,2

                  [h035]
                  Tip=(|cffffcc00E|r) Black King Bar
                  Hotkey=E
                  Buttonpos=2,0

                  [h03A]
                  Tip=(|cffffcc00D|r) Linken's Sphere
                  Hotkey=D
                  Buttonpos=2,1

                  [h03U]
                  Tip=Hood of Defiance
                  Buttonpos=2,2

                  [h03B]
                  Tip=Aegis of the Immortal
                  Buttonpos=3,0

                  [h03N]
                  Tip=Vanguard
                  Buttonpos=3,1

                  [h036]
                  Tip=(|cffffcc00V|r) Manta Style
                  Hotkey=V
                  Buttonpos=3,2

                  [h03M]
                  Tip=Guinsoo's Scythe of Vyse
                  Buttonpos=0,0

                  [h038]
                  Tip=(|cffffcc00A|r) Dagon
                  Hotkey=A
                  Buttonpos=0,1

                  [H0DD]
                  Tip=(|cffffcc00Y|r) Veil of Discord
                  Hotkey=Y
                  Buttonpos=0,2

                  [h03X]
                  Tip=Orchid Malevolence
                  Buttonpos=1,0

                  [h039]
                  Tip=(|cffffcc00S|r) Necronomicon
                  Hotkey=S
                  Buttonpos=1,1

                  [H0DV]
                  Tip=Rod of Atos
                  Buttonpos=1,2

                  [h02Y]
                  Tip=(|cffffcc00E|r) Eul's Scepter of Divinity
                  Hotkey=E
                  Buttonpos=2,0

                  [h03K]
                  Tip=Aghanim's Scepter
                  Buttonpos=2,1

                  [H07t]
                  Tip=(|cffffcc00R|r) Force Staff
                  Hotkey=R
                  Buttonpos=3,0

                  [h03L]
                  Tip=(|cffffcc00F|r) Refresher Orb
                  Hotkey=F
                  Buttonpos=3,1

                  [h030]
                  Tip=(|cffffcc00Q|r) Mekansm
                  Hotkey=Q
                  Buttonpos=0,0

                  [H02i]
                  Tip=(|cffffcc00A|r) Nathrezim Buckler
                  Hotkey=A
                  Buttonpos=0,1

                  [h02H]
                  Tip=(|cffffcc00Y|r) Headdress of Rejuvenation
                  Hotkey=Y
                  Buttonpos=0,2

                  [h03R]
                  Tip=(|cffffcc00W|r) Vladmir's Offering
                  Hotkey=W
                  Buttonpos=1,0

                  [h02J]
                  Tip=Ring of Basilius
                  Buttonpos=1,1

                  [H0CY]
                  Tip=(|cffffcc00X|r) Medallion of Courage
                  Hotkey=X
                  Buttonpos=1,2

                  [H0CO]
                  Tip=Arcane Boots
                  Buttonpos=2,0

                  [H07x]
                  Tip=(|cffffcc00D|r) Khadgar's Pipe of Insight
                  Hotkey=D
                  Buttonpos=2,1

                  [H0D1]
                  Tip=(|cffffcc00C|r) Ancient Janggo of Endurance
                  Hotkey=C
                  Buttonpos=2,2

                  [H0EC]
                  Tip=Ring of Aquila
                  Buttonpos=3,0

                  [h0ba]
                  Tip=(|cffffcc00F|r) Urn of Shadows
                  Hotkey=F
                  Buttonpos=3,1

                  [H0DU]
                  Tip=Tranquil Boots
                  Buttonpos=3,2

                  [h03C]
                  Tip=Divine Rapier
                  Buttonpos=0,0

                  [h03D]
                  Tip=(|cffffcc00A|r) Buriza-do Kyanon
                  Hotkey=A
                  Buttonpos=0,1

                  [h034]
                  Tip=(|cffffcc00Y|r) Crystalys
                  Hotkey=Y
                  Buttonpos=0,2

                  [h03E]
                  Tip=Monkey King Bar
                  Buttonpos=1,0

                  [h02S]
                  Tip=(|cffffcc00S|r) Cranium Basher
                  Hotkey=S
                  Buttonpos=1,1

                  [h03V]
                  Tip=(|cffffcc00X|r) Armlet of Mordiggian
                  Hotkey=X
                  Buttonpos=1,2

                  [h03F]
                  Tip=(|cffffcc00E|r) Radiance
                  Hotkey=E
                  Buttonpos=2,0

                  [h033]
                  Tip=Battle Fury
                  Buttonpos=2,1

                  [h037]
                  Tip=(|cffffcc00C|r) Lothar's Edge
                  Hotkey=C
                  Buttonpos=2,2

                  [h03J]
                  Tip=The Butterfly
                  Buttonpos=3,0

                  [H0EA]
                  Tip=Abyssal Blade
                  Buttonpos=3,1

                  [h0br]
                  Tip=Ethereal Blade
                  Buttonpos=3,2

                  [h031]
                  Tip=Sange and Yasha
                  Buttonpos=0,0

                  [h02R]
                  Tip=(|cffffcc00A|r) Sange
                  Hotkey=A
                  Buttonpos=0,1

                  [h02Q]
                  Tip=(|cffffcc00Y|r) Yasha
                  Hotkey=Y
                  Buttonpos=0,2

                  [h03H]
                  Tip=(|cffffcc00W|r) Satanic
                  Hotkey=W
                  Buttonpos=1,0

                  [h02W]
                  Tip=Helm of the Dominator
                  Buttonpos=1,1

                  [h02X]
                  Tip=(|cffffcc00X|r) Mask of Madness
                  Hotkey=X
                  Buttonpos=1,2

                  [h03P]
                  Tip=(|cffffcc00E|r) Mjollnir
                  Hotkey=E
                  Buttonpos=2,0

                  [h02U]
                  Tip=(|cffffcc00D|r) Maelstrom
                  Hotkey=D
                  Buttonpos=2,1

                  [h02V]
                  Tip=(|cffffcc00C|r) Diffusal Blade
                  Hotkey=C
                  Buttonpos=2,2

                  [h03I]
                  Tip=Eye of Skadi
                  Buttonpos=3,0

                  [h032]
                  Tip=(|cffffcc00F|r) Stygian Desolator
                  Hotkey=F
                  Buttonpos=3,1

                  [H0E9]
                  Tip=Heaven's Halberd
                  Buttonpos=3,2

                  [H02k]
                  Tip=(|cffffcc00Q|r) Boots of Travel
                  Hotkey=Q
                  Buttonpos=0,0

                  [H02l]
                  Tip=(|cffffcc00A|r) Hand of Midas
                  Hotkey=A
                  Buttonpos=0,1

                  [H02n]
                  Tip=(|cffffcc00Y|r) Bracer
                  Hotkey=Y
                  Buttonpos=0,2

                  [H079]
                  Tip=Phase Boots
                  Buttonpos=1,0

                  [H02m]
                  Tip=Oblivion Staff
                  Buttonpos=1,1

                  [H02o]
                  Tip=(|cffffcc00X|r) Wraith Band
                  Hotkey=X
                  Buttonpos=1,2

                  [H014]
                  Tip=Power Treads
                  Buttonpos=2,0

                  [H02g]
                  Tip=Perseverance
                  Buttonpos=2,1

                  [H02p]
                  Tip=(|cffffcc00C|r) Null Talisman
                  Hotkey=C
                  Buttonpos=2,2

                  [h0bq]
                  Tip=(|cffffcc00R|r) Soul Ring
                  Hotkey=R
                  Buttonpos=3,0

                  [H086]
                  Tip=Poor Man's Shield
                  Buttonpos=3,1

                  [H07s]
                  Tip=(|cffffcc00V|r) Magic Wand
                  Hotkey=V
                  Buttonpos=3,2

                  [h012]
                  Tip=(|cffffcc00Q|r) Purchase Gloves of Haste
                  Hotkey=Q
                  Buttonpos=0,0

                  [h021]
                  Tip=(|cffffcc00A|r) Purchase Sobi Mask
                  Hotkey=A
                  Buttonpos=0,1

                  [h074]
                  Tip=(|cffffcc00Y|r) Purchase Magic Stick
                  Hotkey=Y
                  Buttonpos=0,2

                  [h01M]
                  Tip=(|cffffcc00W|r) Purchase Mask of Death
                  Hotkey=W
                  Buttonpos=1,0

                  [h011]
                  Tip=(|cffffcc00S|r) Purchase Boots of Speed
                  Hotkey=S
                  Buttonpos=1,1

                  [H083]
                  Tip=(|cffffcc00X|r) Purchase Talisman of Evasion
                  Hotkey=X
                  Buttonpos=1,2

                  [h01X]
                  Tip=(|cffffcc00E|r) Purchase Ring of Regeneration
                  Hotkey=E
                  Buttonpos=2,0

                  [h01G]
                  Tip=(|cffffcc00D|r) Purchase Gem of True Sight
                  Hotkey=D
                  Buttonpos=2,1

                  [H087]
                  Tip=(|cffffcc00C|r) Purchase Ghost Scepter
                  Hotkey=C
                  Buttonpos=2,2

                  [h01K]
                  Tip=(|cffffcc00R|r) Purchase Kelen's Dagger
                  Hotkey=R
                  Buttonpos=3,0

                  [h01R]
                  Tip=(|cffffcc00F|r) Purchase Planeswalker's Cloak
                  Hotkey=F
                  Buttonpos=3,1

                  [H0EI]
                  Tip=(|cffffcc00V|r) Purchase Shadow Amulet
                  Hotkey=V
                  Buttonpos=3,2

                  [h028]
                  Tip=(|cffffcc00Q|r) Purchase Clarity Potion
                  Hotkey=Q
                  Buttonpos=0,0

                  [h02C]
                  Tip=(|cffffcc00A|r) Purchase Observer Wards
                  Hotkey=A
                  Buttonpos=0,1

                  [h02E]
                  Tip=(|cffffcc00Y|r) Purchase Scroll of Town Portal
                  Hotkey=Y
                  Buttonpos=0,2

                  [h029]
                  Tip=(|cffffcc00W|r) Purchase Healing Salve
                  Hotkey=W
                  Buttonpos=1,0

                  [h02D]
                  Tip=(|cffffcc00S|r) Purchase Sentry Wards
                  Hotkey=S
                  Buttonpos=1,1

                  [H0D3]
                  Tip=(|cffffcc00X|r) Purchase Smoke of Deceit
                  Hotkey=X
                  Buttonpos=1,2

                  [h02A]
                  Tip=(|cffffcc00E|r) Purchase Ancient Tango of Essifation
                  Hotkey=E
                  Buttonpos=2,0

                  [h076]
                  Tip=(|cffffcc00D|r) Purchase Dust of Appearance
                  Hotkey=D
                  Buttonpos=2,1

                  [h02B]
                  Tip=(|cffffcc00R|r) Purchase Empty Bottle
                  Hotkey=R
                  Buttonpos=3,0

                  [h02F]
                  Tip=(|cffffcc00F|r) Purchase Animal Courier
                  Hotkey=F
                  Buttonpos=3,1

                  [H03q]
                  Tip=(|cffffcc00V|r) Flying Courier
                  Hotkey=V
                  Buttonpos=3,2

                  [h01F]
                  Tip=(|cffffcc00Q|r) Purchase Gauntlets of Strength
                  Hotkey=Q
                  Buttonpos=0,0

                  [h016]
                  Tip=(|cffffcc00A|r) Purchase Belt of Giant Strength
                  Hotkey=A
                  Buttonpos=0,1

                  [h01Q]
                  Tip=(|cffffcc00Y|r) Purchase Ogre Axe
                  Hotkey=Y
                  Buttonpos=0,2

                  [h020]
                  Tip=(|cffffcc00W|r) Purchase Slippers of Agility
                  Hotkey=W
                  Buttonpos=1,0

                  [h013]
                  Tip=(|cffffcc00S|r) Purchase Boots of Elvenskin
                  Hotkey=S
                  Buttonpos=1,1

                  [h017]
                  Tip=(|cffffcc00X|r) Purchase Blade of Alacrity
                  Hotkey=X
                  Buttonpos=1,2

                  [h01L]
                  Tip=(|cffffcc00E|r) Purchase Mantle of Intelligence
                  Hotkey=E
                  Buttonpos=2,0

                  [h01Y]
                  Tip=(|cffffcc00D|r) Purchase Robe of the Magi
                  Hotkey=D
                  Buttonpos=2,1

                  [h022]
                  Tip=(|cffffcc00C|r) Purchase Staff of Wizardry
                  Hotkey=C
                  Buttonpos=2,2

                  [h01J]
                  Tip=(|cffffcc00R|r) Purchase Ironwood Branch
                  Hotkey=R
                  Buttonpos=3,0

                  [h015]
                  Tip=(|cffffcc00F|r) Purchase Circlet of Nobility
                  Hotkey=F
                  Buttonpos=3,1

                  [h024]
                  Tip=(|cffffcc00V|r) Purchase Ultimate Orb
                  Hotkey=V
                  Buttonpos=3,2

                  [h018]
                  Tip=(|cffffcc00Q|r) Purchase Claws of Attack
                  Hotkey=Q
                  Buttonpos=0,0

                  [h01W]
                  Tip=(|cffffcc00A|r) Purchase Ring of Protection
                  Hotkey=A
                  Buttonpos=0,1

                  [h01A]
                  Tip=(|cffffcc00Y|r) Purchase Chainmail
                  Hotkey=Y
                  Buttonpos=0,2

                  [h019]
                  Tip=(|cffffcc00W|r) Purchase Broadsword
                  Hotkey=W
                  Buttonpos=1,0

                  [h023]
                  Tip=(|cffffcc00S|r) Purchase Stout Shield
                  Hotkey=S
                  Buttonpos=1,1

                  [h01H]
                  Tip=(|cffffcc00X|r) Purchase Helm of Iron Will
                  Hotkey=X
                  Buttonpos=1,2

                  [h01U]
                  Tip=(|cffffcc00E|r) Purchase Quarterstaff
                  Hotkey=E
                  Buttonpos=2,0

                  [h027]
                  Tip=(|cffffcc00D|r) Purchase Javelin
                  Hotkey=D
                  Buttonpos=2,1

                  [h01S]
                  Tip=(|cffffcc00C|r) Purchase Plate Mail
                  Hotkey=C
                  Buttonpos=2,2

                  [h01B]
                  Tip=(|cffffcc00R|r) Purchase Claymore
                  Hotkey=R
                  Buttonpos=3,0

                  [h01O]
                  Tip=(|cffffcc00F|r) Purchase Mithril Hammer
                  Hotkey=F
                  Buttonpos=3,1

                  [h07w]
                  Tip=(|cffffcc00V|r) Purchase Quelling Blade
                  Hotkey=V
                  Buttonpos=3,2

                  [h01C]
                  Tip=(|cffffcc00Q|r) Purchase Demon Edge
                  Hotkey=Q
                  Buttonpos=0,0

                  [h01I]
                  Tip=(|cffffcc00A|r) Purchase Hyperstone
                  Hotkey=A
                  Buttonpos=0,1

                  [h01E]
                  Tip=(|cffffcc00Y|r) Purchase Energy Booster
                  Hotkey=Y
                  Buttonpos=0,2

                  [h01D]
                  Tip=(|cffffcc00W|r) Purchase Eaglehorn
                  Hotkey=W
                  Buttonpos=1,0

                  [h01V]
                  Tip=(|cffffcc00S|r) Purchase Ring of Health
                  Hotkey=S
                  Buttonpos=1,1

                  [h01T]
                  Tip=(|cffffcc00X|r) Purchase Point Booster
                  Hotkey=X
                  Buttonpos=1,2

                  [h01N]
                  Tip=(|cffffcc00E|r) Purchase Messerschmidt's Reaver
                  Hotkey=E
                  Buttonpos=2,0

                  [h026]
                  Tip=(|cffffcc00D|r) Purchase Void Stone
                  Hotkey=D
                  Buttonpos=2,1

                  [h025]
                  Tip=(|cffffcc00C|r) Purchase Vitality Booster
                  Hotkey=C
                  Buttonpos=2,2

                  [h01Z]
                  Tip=(|cffffcc00R|r) Purchase Sacred Relic
                  Hotkey=R
                  Buttonpos=3,0

                  [h01P]
                  Tip=(|cffffcc00F|r) Purchase Mystic Staff
                  Hotkey=F
                  Buttonpos=3,1

                  [h0cm]
                  Tip=(|cffffcc00V|r) Purchase Orb of Venom
                  Hotkey=V
                  Buttonpos=3,2

                  [h08e]
                  Tip=Purchase Slippers of Agility
                  Buttonpos=0,0

                  [h08f]
                  Tip=Purchase Quelling Blade
                  Buttonpos=0,1

                  [H08v]
                  Tip=Purchase Talisman of Evasion
                  Buttonpos=0,2

                  [h08p]
                  Tip=Purchase Boots of Elvenskin
                  Buttonpos=1,0

                  [h08s]
                  Tip=Purchase Gloves of Haste
                  Buttonpos=1,1

                  [h08w]
                  Tip=Purchase Kelen's Dagger
                  Buttonpos=1,2

                  [h08q]
                  Tip=Purchase Belt of Giant Strength
                  Buttonpos=2,0

                  [h08t]
                  Tip=Purchase Claws of Attack
                  Buttonpos=2,1

                  [h08x]
                  Tip=Purchase Ultimate Orb
                  Buttonpos=2,2

                  [h08r]
                  Tip=Purchase Robe of the Magi
                  Buttonpos=3,0

                  [h08u]
                  Tip=Purchase Quarterstaff
                  Buttonpos=3,1

                  [H0D0]
                  Tip=Purchase Chainmail
                  Buttonpos=3,2

                  [h08h]
                  Tip=(|cffffcc00Q|r) Purchase Scroll of Town Portal
                  Hotkey=Q
                  Buttonpos=0,0

                  [h08L]
                  Tip=Purchase Ring of Regeneration
                  Buttonpos=0,1

                  [h08o]
                  Tip=Purchase Mask of Death
                  Buttonpos=0,2

                  [h08i]
                  Tip=Purchase Magic Stick
                  Buttonpos=1,0

                  [h08g]
                  Tip=Purchase Ring of Health
                  Buttonpos=1,1

                  [h093]
                  Tip=(|cffffcc00X|r) Purchase Energy Booster
                  Hotkey=X
                  Buttonpos=1,2

                  [h08j]
                  Tip=Purchase Sobi Mask
                  Buttonpos=2,0

                  [h08m]
                  Tip=Purchase Planeswalker's Cloak
                  Buttonpos=2,1

                  [h0bo]
                  Tip=Purchase Boots of Speed
                  Buttonpos=2,2

                  [h08k]
                  Tip=Purchase Stout Shield
                  Buttonpos=3,0

                  [h08n]
                  Tip=Purchase Helm of Iron Will
                  Buttonpos=3,1

                  [h0cn]
                  Tip=Purchase Orb of Venom
                  Buttonpos=3,2

                  [H0A3]
                  Tip=Revive Hero
                  Buttonpos=0,0

                  [A14D]
                  Tip=(|cffffcc00Y|r) Pickup All Items
                  Hotkey=Y
                  Buttonpos=0,2

                  [A14C]
                  Tip=(|cffffcc00X|r) Drop Items
                  Hotkey=X
                  Buttonpos=1,2

                  [A0K5]
                  Tip=(|cffffcc00C|r) Disassemble
                  Hotkey=C
                  Buttonpos=2,2

                  [A141]
                  Tip=(|cffffcc00R|r) Activate Glyph of Fortification
                  Hotkey=R
                  Buttonpos=3,0

                  [A0HU]
                  Tip=(|cffffcc00F|r) Freeze Hero
                  Hotkey=F
                  Buttonpos=3,1

                  [A0HX]
                  Tip=(|cffffcc00V|r) Unfreeze Hero
                  Hotkey=V
                  Buttonpos=3,2

                  [a1e9]
                  Tip=(|cffffcc00Q|r) Crystal Nova - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Crystal Nova - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Crystal Nova - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Crystal Nova - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Crystal Nova - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a04c]
                  Tip=(|cffffcc00W|r) Frostbite - [|cffffcc00Level 1|r],(|cffffcc00W|r) Frostbite - [|cffffcc00Level 2|r],(|cffffcc00W|r) Frostbite - [|cffffcc00Level 3|r],(|cffffcc00W|r) Frostbite - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Frostbite - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a03r]
                  Tip=(|cffffcc00R|r) Freezing Field - [|cffffcc00Level 1|r],(|cffffcc00R|r) Freezing Field - [|cffffcc00Level 2|r],(|cffffcc00R|r) Freezing Field - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Freezing Field - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0av]
                  Tip=(|cffffcc00R|r) Freezing Field (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Freezing Field (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Freezing Field (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Freezing Field (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0dw]
                  Tip=Untouchable - [|cffffcc00Level 1|r],Untouchable - [|cffffcc00Level 2|r],Untouchable - [|cffffcc00Level 3|r],Untouchable - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Untouchable - [|cffffcc00Level %d|r]
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0dx]
                  Tip=(|cffffcc00W|r) Enchant - [|cffffcc00Level 1|r],(|cffffcc00W|r) Enchant - [|cffffcc00Level 2|r],(|cffffcc00W|r) Enchant - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00W|r) Learn Enchant - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,0
                  Researchbuttonpos=1,0

                  [a01b]
                  Tip=(|cffffcc00E|r) Nature's Attendants - [|cffffcc00Level 1|r],(|cffffcc00E|r) Nature's Attendants - [|cffffcc00Level 2|r],(|cffffcc00E|r) Nature's Attendants - [|cffffcc00Level 3|r],(|cffffcc00E|r) Nature's Attendants - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Nature's Attendants - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0dy]
                  Tip=(|cffffcc00R|r) Impetus - [|cffffcc00Level 1|r],(|cffffcc00R|r) Impetus - [|cffffcc00Level 2|r],(|cffffcc00R|r) Impetus - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00R|r) Learn Impetus - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Unbuttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1wb]
                  Tip=(|cffffcc00R|r) Impetus (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Impetus (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Impetus (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00R|r) Learn Impetus (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Unbuttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0s9]
                  Tip=(|cffffcc00Q|r) Illusory Orb - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Illusory Orb - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Illusory Orb - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Illusory Orb - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Illusory Orb - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0sc]
                  Tip=(|cffffcc00W|r) Wanning Rift - [|cffffcc00Level 1|r],(|cffffcc00W|r) Wanning Rift - [|cffffcc00Level 2|r],(|cffffcc00W|r) Wanning Rift - [|cffffcc00Level 3|r],(|cffffcc00W|r) Wanning Rift - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Wanning Rift - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0sa]
                  Tip=(|cffffcc00D|r) Ethereal Jaunt - [|cffffcc00Level 1|r],(|cffffcc00D|r) Ethereal Jaunt - [|cffffcc00Level 2|r],(|cffffcc00D|r) Ethereal Jaunt - [|cffffcc00Level 3|r],(|cffffcc00D|r) Ethereal Jaunt - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00X|r) Learn Ethereal Jaunt - [|cffffcc00Level %d|r]
                  Hotkey=D
                  Researchhotkey=X
                  Buttonpos=2,1
                  Researchbuttonpos=1,2

                  [a0sb]
                  Tip=(|cffffcc00E|r) Phase Shift - [|cffffcc00Level 1|r],(|cffffcc00E|r) Phase Shift - [|cffffcc00Level 2|r],(|cffffcc00E|r) Phase Shift - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00E|r) Learn Phase Shift - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Unbuttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0s8]
                  Tip=(|cffffcc00R|r) Dream Coil - [|cffffcc00Level 1|r],(|cffffcc00R|r) Dream Coil - [|cffffcc00Level 2|r],(|cffffcc00R|r) Dream Coil - [|cffffcc00Level 3|r],(|cffffcc00R|r) Dream Coil - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00R|r) Learn Dream Coil - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1qp]
                  Tip=(|cffffcc00R|r) Dream Coil(Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Dream Coil(Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Dream Coil(Aghanim's Scepter) - [|cffffcc00Level 3|r],(|cffffcc00R|r) Dream Coil(Aghanim's Scepter) - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00R|r) Learn Dream Coil(Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0km]
                  Tip=(|cffffcc00Q|r) Penitence - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Penitence - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Penitence - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Penitence - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Penitence - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [A2MC]
                  Tip=(|cffffcc00W|r) Test of Faith - [|cffffcc00Level 1|r],(|cffffcc00W|r) Test of Faith - [|cffffcc00Level 2|r],(|cffffcc00W|r) Test of Faith - [|cffffcc00Level 3|r],(|cffffcc00W|r) Test of Faith - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Y|r) Learn Test of Faith - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=Y
                  Buttonpos=1,0
                  Researchbuttonpos=0,2

                  [A28T]
                  Tip=(|cffffcc00E|r) Holy Persuasion - [|cffffcc00Level 1|r],(|cffffcc00E|r) Holy Persuasion - [|cffffcc00Level 2|r],(|cffffcc00E|r) Holy Persuasion - [|cffffcc00Level 3|r],(|cffffcc00E|r) Holy Persuasion - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Holy Persuasion - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0Lt]
                  Tip=(|cffffcc00R|r) Hand of God - [|cffffcc00Level 1|r],(|cffffcc00R|r) Hand of God - [|cffffcc00Level 2|r],(|cffffcc00R|r) Hand of God - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Hand of God - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1cs]
                  Tip=(|cffffcc00R|r) Hand of God (Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Hand of God (Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Hand of God (Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Hand of God (Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a085]
                  Tip=(|cffffcc00Q|r) Illuminate - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Illuminate - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Illuminate - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Illuminate - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Illuminate - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [A121]
                  Tip=(|cffffcc00Q|r) Discharge Illuminate
                  Hotkey=Q
                  Buttonpos=0,0

                  [A10U]
                  Tip=(|cffffcc00E|r) Recall
                  Hotkey=E
                  Buttonpos=2,0

                  [A11Y]
                  Tip=(|cffffcc00E|r) Recall
                  Hotkey=E
                  Buttonpos=2,0

                  [A11Z]
                  Tip=(|cffffcc00E|r) Recall
                  Hotkey=E
                  Buttonpos=2,0

                  [A10X]
                  Tip=(|cffffcc00W|r) Mana Leak - [|cffffcc00Level 1|r],(|cffffcc00W|r) Mana Leak - [|cffffcc00Level 2|r],(|cffffcc00W|r) Mana Leak - [|cffffcc00Level 3|r],(|cffffcc00W|r) Mana Leak - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Mana Leak - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [A11X]
                  Tip=(|cffffcc00D|r) Blinding Light
                  Hotkey=D
                  Buttonpos=2,1

                  [A11V]
                  Tip=(|cffffcc00D|r) Blinding Light
                  Hotkey=D
                  Buttonpos=2,1

                  [A11W]
                  Tip=(|cffffcc00D|r) Blinding Light
                  Hotkey=D
                  Buttonpos=2,1

                  [A112]
                  Tip=(|cffffcc00X|r) Chakra Magic - [|cffffcc00Level 1|r],(|cffffcc00X|r) Chakra Magic - [|cffffcc00Level 2|r],(|cffffcc00X|r) Chakra Magic - [|cffffcc00Level 3|r],(|cffffcc00X|r) Chakra Magic - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Chakra Magic - [|cffffcc00Level %d|r]
                  Hotkey=X
                  Researchhotkey=E
                  Buttonpos=1,2
                  Researchbuttonpos=2,0

                  [A11T]
                  Tip=(|cffffcc00R|r) Spirit Form - [|cffffcc00Level 1|r],(|cffffcc00R|r) Spirit Form - [|cffffcc00Level 2|r],(|cffffcc00R|r) Spirit Form - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Spirit Form - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a020]
                  Tip=(|cffffcc00Q|r) Arc Lightning - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Arc Lightning - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Arc Lightning - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Arc Lightning - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Arc Lightning - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0jc]
                  Tip=(|cffffcc00W|r) Lightning Bolt - [|cffffcc00Level 1|r],(|cffffcc00W|r) Lightning Bolt - [|cffffcc00Level 2|r],(|cffffcc00W|r) Lightning Bolt - [|cffffcc00Level 3|r],(|cffffcc00W|r) Lightning Bolt - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Lightning Bolt - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0n5]
                  Tip=Static Field - [|cffffcc00Level 1|r],Static Field - [|cffffcc00Level 2|r],Static Field - [|cffffcc00Level 3|r],Static Field - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Static Field - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [A29G]
                  Tip=(|cffffcc00R|r) Thundergod's Wrath - [|cffffcc00Level 1|r],(|cffffcc00R|r) Thundergod's Wrath - [|cffffcc00Level 2|r],(|cffffcc00R|r) Thundergod's Wrath - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Thundergod's Wrath - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [A29H]
                  Tip=(|cffffcc00R|r) Thundergod's Wrath (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Thundergod's Wrath (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Thundergod's Wrath (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Thundergod's Wrath (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [A21E]
                  Tip=(|cffffcc00Q|r) Sprout - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Sprout - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Sprout - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Sprout - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Sprout - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a01o]
                  Tip=(|cffffcc00E|r) Teleportation - [|cffffcc00Level 1|r],(|cffffcc00E|r) Teleportation - [|cffffcc00Level 2|r],(|cffffcc00E|r) Teleportation - [|cffffcc00Level 3|r],(|cffffcc00E|r) Teleportation - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Teleportation - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=W
                  Buttonpos=2,0
                  Researchbuttonpos=1,0

                  [a1w8]
                  Tip=(|cffffcc00R|r) Wrath of Nature - [|cffffcc00Level 1|r],(|cffffcc00R|r) Wrath of Nature - [|cffffcc00Level 2|r],(|cffffcc00R|r) Wrath of Nature - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Wrath of Nature - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1w9]
                  Tip=(|cffffcc00R|r) Wrath of Nature (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Wrath of Nature (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Wrath of Nature (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Wrath of Nature (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [A14L]
                  Tip=(|cffffcc00Q|r) Curse of the Silent - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Curse of the Silent - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Curse of the Silent - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Curse of the Silent - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Curse of the Silent - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0Lz]
                  Tip=(|cffffcc00W|r) Glaives of Wisdom - [|cffffcc00Level 1|r],(|cffffcc00W|r) Glaives of Wisdom - [|cffffcc00Level 2|r],(|cffffcc00W|r) Glaives of Wisdom - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00W|r) Learn Glaives of Wisdom - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,0
                  Researchbuttonpos=1,0

                  [A2NT]
                  Tip=(|cffffcc00E|r) Last Word - [|cffffcc00Level 1|r],(|cffffcc00E|r) Last Word - [|cffffcc00Level 2|r],(|cffffcc00E|r) Last Word - [|cffffcc00Level 3|r],(|cffffcc00E|r) Last Word - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Last Word - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0L3]
                  Tip=(|cffffcc00R|r) Global Silence - [|cffffcc00Level 1|r],(|cffffcc00R|r) Global Silence - [|cffffcc00Level 2|r],(|cffffcc00R|r) Global Silence - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Global Silence - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a01f]
                  Tip=(|cffffcc00Q|r) Dragon Slave - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Dragon Slave - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Dragon Slave - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Dragon Slave - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Dragon Slave - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a027]
                  Tip=(|cffffcc00W|r) Light Strike Array - [|cffffcc00Level 1|r],(|cffffcc00W|r) Light Strike Array - [|cffffcc00Level 2|r],(|cffffcc00W|r) Light Strike Array - [|cffffcc00Level 3|r],(|cffffcc00W|r) Light Strike Array - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Light Strike Array - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a18x]
                  Tip=Fiery Soul - [|cffffcc00Level 1|r],Fiery Soul - [|cffffcc00Level 2|r],Fiery Soul - [|cffffcc00Level 3|r],Fiery Soul - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Fiery Soul - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a01p]
                  Tip=(|cffffcc00R|r) Laguna Blade - [|cffffcc00Level 1|r],(|cffffcc00R|r) Laguna Blade - [|cffffcc00Level 2|r],(|cffffcc00R|r) Laguna Blade - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Laguna Blade - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a09z]
                  Tip=(|cffffcc00R|r) Laguna Blade (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Laguna Blade (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Laguna Blade (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Laguna Blade (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [A14P]
                  Tip=(|cffffcc00Q|r) Static Remnant - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Static Remnant - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Static Remnant - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Static Remnant - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Static Remnant - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [A14R]
                  Tip=(|cffffcc00W|r) Electric Vortex - [|cffffcc00Level 1|r],(|cffffcc00W|r) Electric Vortex - [|cffffcc00Level 2|r],(|cffffcc00W|r) Electric Vortex - [|cffffcc00Level 3|r],(|cffffcc00W|r) Electric Vortex - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Electric Vortex - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [A0QW]
                  Tip=Overload - [|cffffcc00Level 1|r],Overload - [|cffffcc00Level 2|r],Overload - [|cffffcc00Level 3|r],Overload - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Overload - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [A14O]
                  Tip=(|cffffcc00R|r) Ball Lightning - [|cffffcc00Level 1|r],(|cffffcc00R|r) Ball Lightning - [|cffffcc00Level 2|r],(|cffffcc00R|r) Ball Lightning - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Ball Lightning - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [A12J]
                  Tip=(|cffffcc00Q|r) Shackleshot - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Shackleshot - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Shackleshot - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Shackleshot - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Shackleshot - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [A12K]
                  Tip=(|cffffcc00W|r) Powershot - [|cffffcc00Level 1|r],(|cffffcc00W|r) Powershot - [|cffffcc00Level 2|r],(|cffffcc00W|r) Powershot - [|cffffcc00Level 3|r],(|cffffcc00W|r) Powershot - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Powershot - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [A14i]
                  Tip=(|cffffcc00E|r) Windrunner - [|cffffcc00Level 1|r],(|cffffcc00E|r) Windrunner - [|cffffcc00Level 2|r],(|cffffcc00E|r) Windrunner - [|cffffcc00Level 3|r],(|cffffcc00E|r) Windrunner - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Windrunner - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [A12P]
                  Tip=(|cffffcc00R|r) Focus Fire - [|cffffcc00Level 1|r],(|cffffcc00R|r) Focus Fire - [|cffffcc00Level 2|r],(|cffffcc00R|r) Focus Fire - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Focus Fire - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [A1D6]
                  Tip=(|cffffcc00R|r) Focus Fire (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Focus Fire (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Focus Fire (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Focus Fire (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1tv]
                  Tip=(|cffffcc00Q|r) Thunder Strike - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Thunder Strike - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Thunder Strike - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Thunder Strike - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Thunder Strike - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a1sw]
                  Tip=(|cffffcc00W|r) Glimpse - [|cffffcc00Level 1|r],(|cffffcc00W|r) Glimpse - [|cffffcc00Level 2|r],(|cffffcc00W|r) Glimpse - [|cffffcc00Level 3|r],(|cffffcc00W|r) Glimpse - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Glimpse - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a1su]
                  Tip=(|cffffcc00E|r) Kinetic Field - [|cffffcc00Level 1|r],(|cffffcc00E|r) Kinetic Field - [|cffffcc00Level 2|r],(|cffffcc00E|r) Kinetic Field - [|cffffcc00Level 3|r],(|cffffcc00E|r) Kinetic Field - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Kinetic Field - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a1u6]
                  Tip=(|cffffcc00R|r) Static Storm - [|cffffcc00Level 1|r],(|cffffcc00R|r) Static Storm - [|cffffcc00Level 2|r],(|cffffcc00R|r) Static Storm - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Static Storm - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [A27F]
                  Tip=(|cffffcc00Q|r) Telekinesis - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Telekinesis - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Telekinesis - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Telekinesis - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Telekinesis - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [A27X]
                  Tip=(|cffffcc00Q|r) Telekinesis Land - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Telekinesis Land - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Telekinesis Land - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Telekinesis Land - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Telekinesis Land - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [A27G]
                  Tip=(|cffffcc00W|r) Fade Bolt - [|cffffcc00Level 1|r],(|cffffcc00W|r) Fade Bolt - [|cffffcc00Level 2|r],(|cffffcc00W|r) Fade Bolt - [|cffffcc00Level 3|r],(|cffffcc00W|r) Fade Bolt - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Fade Bolt - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [A27V]
                  Tip=Null Field - [|cffffcc00Level 1|r],Null Field - [|cffffcc00Level 2|r],Null Field - [|cffffcc00Level 3|r],Null Field - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Null Field - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [A27H]
                  Tip=(|cffffcc00R|r) Spell Steal - [|cffffcc00Level 1|r],(|cffffcc00R|r) Spell Steal - [|cffffcc00Level 2|r],(|cffffcc00R|r) Spell Steal - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Spell Steal - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1eL]
                  Tip=(|cffffcc00Q|r) Sticky Napalm - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Sticky Napalm - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Sticky Napalm - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Sticky Napalm - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Sticky Napalm - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a19v]
                  Tip=(|cffffcc00W|r) Flamebreak - [|cffffcc00Level 1|r],(|cffffcc00W|r) Flamebreak - [|cffffcc00Level 2|r],(|cffffcc00W|r) Flamebreak - [|cffffcc00Level 3|r],(|cffffcc00W|r) Flamebreak - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Flamebreak - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a19z]
                  Tip=(|cffffcc00E|r) Firefly - [|cffffcc00Level 1|r],(|cffffcc00E|r) Firefly - [|cffffcc00Level 2|r],(|cffffcc00E|r) Firefly - [|cffffcc00Level 3|r],(|cffffcc00E|r) Firefly - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Firefly - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a19o]
                  Tip=(|cffffcc00R|r) Flaming Lasso - [|cffffcc00Level 1|r],(|cffffcc00R|r) Flaming Lasso - [|cffffcc00Level 2|r],(|cffffcc00R|r) Flaming Lasso - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Flaming Lasso - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a05j]
                  Tip=(|cffffcc00Q|r) Land Mines - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Land Mines - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Land Mines - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Land Mines - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Land Mines - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a1wf]
                  Tip=(|cffffcc00R|r) Focused Detonate
                  Hotkey=R
                  Buttonpos=3,0

                  [a06h]
                  Tip=(|cffffcc00W|r) Stasis Trap - [|cffffcc00Level 1|r],(|cffffcc00W|r) Stasis Trap - [|cffffcc00Level 2|r],(|cffffcc00W|r) Stasis Trap - [|cffffcc00Level 3|r],(|cffffcc00W|r) Stasis Trap - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Stasis Trap - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a06b]
                  Tip=(|cffffcc00E|r) Suicide Squad,(|cffffcc00E|r)  Attack! - [|cffffcc00Level 1|r],(|cffffcc00E|r) Suicide Squad,(|cffffcc00E|r)  Attack! - [|cffffcc00Level 2|r],(|cffffcc00E|r) Suicide Squad,(|cffffcc00E|r)  Attack! - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00E|r) Learn Suicide Squad,Attack! - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Unbuttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0ak]
                  Tip=(|cffffcc00X|r) Remote Mines - [|cffffcc00Level 1|r],(|cffffcc00X|r) Remote Mines - [|cffffcc00Level 2|r],(|cffffcc00X|r) Remote Mines - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Remote Mines - [|cffffcc00Level %d|r]
                  Hotkey=X
                  Researchhotkey=R
                  Buttonpos=1,2
                  Researchbuttonpos=3,0

                  [a1fy]
                  Tip=(|cffffcc00R|r) Remote Mines (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Remote Mines (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Remote Mines (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Remote Mines (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a02t]
                  Tip=(|cffffcc00D|r) Detonate
                  Hotkey=D
                  Buttonpos=2,1

                  [a0am]
                  Tip=(|cffffcc00Q|r) Detonate
                  Hotkey=Q
                  Buttonpos=0,0

                  [a0a3]
                  Tip=(|cffffcc00Q|r) Detonate
                  Hotkey=Q
                  Buttonpos=0,0

                  [a0a4]
                  Tip=(|cffffcc00Q|r) Detonate
                  Hotkey=Q
                  Buttonpos=0,0

                  [a1fz]
                  Tip=(|cffffcc00Q|r) Detonate
                  Hotkey=Q
                  Buttonpos=0,0

                  [A21W]
                  Tip=(|cffffcc00Q|r) Quas - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Quas - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Quas - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Quas - [|cffffcc00Level 4|r],(|cffffcc00Q|r) Quas - [|cffffcc00Level 5|r],(|cffffcc00Q|r) Quas - [|cffffcc00Level 6|r],(|cffffcc00Q|r) Quas - [|cffffcc00Level 7|r]
                  Researchtip=(|cffffcc00Q|r) Learn Quas - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [A21X]
                  Tip=(|cffffcc00W|r) Wex - [|cffffcc00Level 1|r],(|cffffcc00W|r) Wex - [|cffffcc00Level 2|r],(|cffffcc00W|r) Wex - [|cffffcc00Level 3|r],(|cffffcc00W|r) Wex - [|cffffcc00Level 4|r],(|cffffcc00W|r) Wex - [|cffffcc00Level 5|r],(|cffffcc00W|r) Wex - [|cffffcc00Level 6|r],(|cffffcc00W|r) Wex - [|cffffcc00Level 7|r]
                  Researchtip=(|cffffcc00W|r) Learn Wex - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [A21V]
                  Tip=(|cffffcc00E|r) Exort - [|cffffcc00Level 1|r],(|cffffcc00E|r) Exort - [|cffffcc00Level 2|r],(|cffffcc00E|r) Exort - [|cffffcc00Level 3|r],(|cffffcc00E|r) Exort - [|cffffcc00Level 4|r],(|cffffcc00E|r) Exort - [|cffffcc00Level 5|r],(|cffffcc00E|r) Exort - [|cffffcc00Level 6|r],(|cffffcc00E|r) Exort - [|cffffcc00Level 7|r]
                  Researchtip=(|cffffcc00E|r) Learn Exort - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [A21Y]
                  Tip=(|cffffcc00R|r) Invoke - [|cffffcc00Level 1|r],(|cffffcc00R|r) Invoke - [|cffffcc00Level 2|r],(|cffffcc00R|r) Invoke - [|cffffcc00Level 3|r],(|cffffcc00R|r) Invoke - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00R|r) Learn Invoke - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [A1GU]
                  Tip=(|cffffcc00R|r) Invoke (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Invoke (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Invoke (Aghanim's Scepter) - [|cffffcc00Level 3|r],(|cffffcc00R|r) Invoke (Aghanim's Scepter) - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00R|r) Learn Invoke (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0vn]
                  Tip=(|cffffcc00S|r) Chaos Meteor [EEW] - [|cffffcc00Level 1|r],(|cffffcc00S|r) Chaos Meteor [EEW] - [|cffffcc00Level 2|r],(|cffffcc00S|r) Chaos Meteor [EEW] - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Y|r) Learn Chaos Meteor [EEW] - [|cffffcc00Level %d|r]
                  Hotkey=S
                  Researchhotkey=Y
                  Buttonpos=1,1
                  Researchbuttonpos=0,2

                  [a0vs]
                  Tip=(|cffffcc00S|r) EMP [WWE] - [|cffffcc00Level 1|r],(|cffffcc00S|r) EMP [WWE] - [|cffffcc00Level 2|r],(|cffffcc00S|r) EMP [WWE] - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Y|r) Learn EMP [WWE] - [|cffffcc00Level %d|r]
                  Hotkey=S
                  Researchhotkey=Y
                  Buttonpos=1,1
                  Researchbuttonpos=0,2

                  [a0vk]
                  Tip=(|cffffcc00S|r) Tornado [WWQ] - [|cffffcc00Level 1|r],(|cffffcc00S|r) Tornado [WWQ] - [|cffffcc00Level 2|r],(|cffffcc00S|r) Tornado [WWQ] - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Y|r) Learn Tornado [WWQ] - [|cffffcc00Level %d|r]
                  Hotkey=S
                  Researchhotkey=Y
                  Buttonpos=1,1
                  Researchbuttonpos=0,2

                  [a0xl]
                  Tip=(|cffffcc00S|r) Ghost Walk [QQW] - [|cffffcc00Level 1|r],(|cffffcc00S|r) Ghost Walk [QQW] - [|cffffcc00Level 2|r],(|cffffcc00S|r) Ghost Walk [QQW] - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Y|r) Learn Ghost Walk [QQW] - [|cffffcc00Level %d|r]
                  Hotkey=S
                  Researchhotkey=Y
                  Buttonpos=1,1
                  Researchbuttonpos=0,2

                  [a0vm]
                  Tip=(|cffffcc00S|r) Deafeaning Blast [QWE] - [|cffffcc00Level 1|r],(|cffffcc00S|r) Deafeaning Blast [QWE] - [|cffffcc00Level 2|r],(|cffffcc00S|r) Deafeaning Blast [QWE] - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Y|r) Learn Deafeaning Blast [QWE] - [|cffffcc00Level %d|r]
                  Hotkey=S
                  Researchhotkey=Y
                  Buttonpos=1,1
                  Researchbuttonpos=0,2

                  [a0vp]
                  Tip=(|cffffcc00S|r) Ice Wall [QQE] - [|cffffcc00Level 1|r],(|cffffcc00S|r) Ice Wall [QQE] - [|cffffcc00Level 2|r],(|cffffcc00S|r) Ice Wall [QQE] - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Y|r) Learn Ice Wall [QQE] - [|cffffcc00Level %d|r]
                  Hotkey=S
                  Researchhotkey=Y
                  Buttonpos=1,1
                  Researchbuttonpos=0,2

                  [a0vg]
                  Tip=(|cffffcc00S|r) Sun Strike [EEE] - [|cffffcc00Level 1|r],(|cffffcc00S|r) Sun Strike [EEE] - [|cffffcc00Level 2|r],(|cffffcc00S|r) Sun Strike [EEE] - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Y|r) Learn Sun Strike [EEE] - [|cffffcc00Level %d|r]
                  Hotkey=S
                  Researchhotkey=Y
                  Buttonpos=1,1
                  Researchbuttonpos=0,2

                  [a0vq]
                  Tip=(|cffffcc00S|r) Alacrity [WWW] - [|cffffcc00Level 1|r],(|cffffcc00S|r) Alacrity [WWW] - [|cffffcc00Level 2|r],(|cffffcc00S|r) Alacrity [WWW] - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Y|r) Learn Alacrity [WWW] - [|cffffcc00Level %d|r]
                  Hotkey=S
                  Researchhotkey=Y
                  Buttonpos=1,1
                  Researchbuttonpos=0,2

                  [a0vo]
                  Tip=(|cffffcc00S|r) Forge Spirit [EEQ] - [|cffffcc00Level 1|r],(|cffffcc00S|r) Forge Spirit [EEQ] - [|cffffcc00Level 2|r],(|cffffcc00S|r) Forge Spirit [EEQ] - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Y|r) Learn Forge Spirit [EEQ] - [|cffffcc00Level %d|r]
                  Hotkey=S
                  Researchhotkey=Y
                  Buttonpos=1,1
                  Researchbuttonpos=0,2

                  [a0vz]
                  Tip=(|cffffcc00S|r) Cold Snap [QQQ] - [|cffffcc00Level 1|r],(|cffffcc00S|r) Cold Snap [QQQ] - [|cffffcc00Level 2|r],(|cffffcc00S|r) Cold Snap [QQQ] - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Y|r) Learn Cold Snap [QQQ] - [|cffffcc00Level %d|r]
                  Hotkey=S
                  Researchhotkey=Y
                  Buttonpos=1,1
                  Researchbuttonpos=0,2

                  [a08x]
                  Tip=(|cffffcc00Q|r) Grave Chill - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Grave Chill - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Grave Chill - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Grave Chill - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Grave Chill - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a1na]
                  Tip=(|cffffcc00W|r) Soul Assumption - [|cffffcc00Level 1|r],(|cffffcc00W|r) Soul Assumption - [|cffffcc00Level 2|r],(|cffffcc00W|r) Soul Assumption - [|cffffcc00Level 3|r],(|cffffcc00W|r) Soul Assumption - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Soul Assumption - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0vx]
                  Tip=Gravekeeper's Cloak - [|cffffcc00Level 1|r],Gravekeeper's Cloak - [|cffffcc00Level 2|r],Gravekeeper's Cloak - [|cffffcc00Level 3|r],Gravekeeper's Cloak - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Gravekeeper's Cloak - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a1ne]
                  Tip=(|cffffcc00R|r) Summon Familiars - [|cffffcc00Level 1|r],(|cffffcc00R|r) Summon Familiars - [|cffffcc00Level 2|r],(|cffffcc00R|r) Summon Familiars - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00R|r) Learn Summon Familiars - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Unbuttonpos=3,2
                  Researchbuttonpos=3,0

                  [a1nb]
                  Tip=(|cffffcc00Q|r) Stone Form
                  UnTip=(|cffffcc00Q|r) Stone Form
                  Hotkey=Q
                  Unhotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [a1nc]
                  Tip=(|cffffcc00Q|r) Stone Form
                  UnTip=(|cffffcc00Q|r) Stone Form
                  Hotkey=Q
                  Unhotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [a1nd]
                  Tip=(|cffffcc00Q|r) Stone Form
                  UnTip=(|cffffcc00Q|r) Stone Form
                  Hotkey=Q
                  Unhotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [a1nL]
                  Tip=(|cffffcc00Q|r) Stone Form
                  UnTip=(|cffffcc00Q|r) Stone Form
                  Hotkey=Q
                  Unhotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [a1nm]
                  Tip=(|cffffcc00Q|r) Stone Form
                  UnTip=(|cffffcc00Q|r) Stone Form
                  Hotkey=Q
                  Unhotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [a1nn]
                  Tip=(|cffffcc00Q|r) Stone Form
                  UnTip=(|cffffcc00Q|r) Stone Form
                  Hotkey=Q
                  Unhotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [a04w]
                  Tip=(|cffffcc00Q|r) Fireblast - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Fireblast - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Fireblast - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Fireblast - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Fireblast - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a011]
                  Tip=(|cffffcc00W|r) Ignite - [|cffffcc00Level 1|r],(|cffffcc00W|r) Ignite - [|cffffcc00Level 2|r],(|cffffcc00W|r) Ignite - [|cffffcc00Level 3|r],(|cffffcc00W|r) Ignite - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Ignite - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a083]
                  Tip=(|cffffcc00E|r) Bloodlust - [|cffffcc00Level 1|r],(|cffffcc00E|r) Bloodlust - [|cffffcc00Level 2|r],(|cffffcc00E|r) Bloodlust - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00E|r) Learn Bloodlust - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Unbuttonpos=2,0
                  Researchbuttonpos=2,0

                  [a088]
                  Tip=Multi Cast - [|cffffcc00Level 1|r],Multi Cast - [|cffffcc00Level 2|r],Multi Cast - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Multi Cast - [|cffffcc00Level %d|r]
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a089]
                  Tip=(|cffffcc00Q|r) Fireblast - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Fireblast - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Fireblast - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Fireblast - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Fireblast - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a007]
                  Tip=(|cffffcc00W|r) Ignite - [|cffffcc00Level 1|r],(|cffffcc00W|r) Ignite - [|cffffcc00Level 2|r],(|cffffcc00W|r) Ignite - [|cffffcc00Level 3|r],(|cffffcc00W|r) Ignite - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Ignite - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a08f]
                  Tip=(|cffffcc00E|r) Bloodlust - [|cffffcc00Level 1|r],(|cffffcc00E|r) Bloodlust - [|cffffcc00Level 2|r],(|cffffcc00E|r) Bloodlust - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00E|r) Learn Bloodlust - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Unbuttonpos=2,0
                  Researchbuttonpos=2,0

                  [a08a]
                  Tip=(|cffffcc00Q|r) Fireblast - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Fireblast - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Fireblast - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Fireblast - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Fireblast - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a01t]
                  Tip=(|cffffcc00W|r) Ignite - [|cffffcc00Level 1|r],(|cffffcc00W|r) Ignite - [|cffffcc00Level 2|r],(|cffffcc00W|r) Ignite - [|cffffcc00Level 3|r],(|cffffcc00W|r) Ignite - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Ignite - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a08g]
                  Tip=(|cffffcc00E|r) Bloodlust - [|cffffcc00Level 1|r],(|cffffcc00E|r) Bloodlust - [|cffffcc00Level 2|r],(|cffffcc00E|r) Bloodlust - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00E|r) Learn Bloodlust - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Unbuttonpos=2,0
                  Researchbuttonpos=2,0

                  [a08d]
                  Tip=(|cffffcc00Q|r) Fireblast - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Fireblast - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Fireblast - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Fireblast - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Fireblast - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a00f]
                  Tip=(|cffffcc00W|r) Ignite - [|cffffcc00Level 1|r],(|cffffcc00W|r) Ignite - [|cffffcc00Level 2|r],(|cffffcc00W|r) Ignite - [|cffffcc00Level 3|r],(|cffffcc00W|r) Ignite - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Ignite - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a08i]
                  Tip=(|cffffcc00E|r) Bloodlust - [|cffffcc00Level 1|r],(|cffffcc00E|r) Bloodlust - [|cffffcc00Level 2|r],(|cffffcc00E|r) Bloodlust - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00E|r) Learn Bloodlust - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Unbuttonpos=2,0
                  Researchbuttonpos=2,0

                  [A2KQ]
                  Tip=(|cffffcc00D|r) Unrefined Fireblast - [|cffffcc00Level 1|r],(|cffffcc00D|r) Unrefined Fireblast - [|cffffcc00Level 2|r],(|cffffcc00D|r) Unrefined Fireblast - [|cffffcc00Level 3|r],(|cffffcc00D|r) Unrefined Fireblast - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00X|r) Learn Unrefined Fireblast - [|cffffcc00Level %d|r]
                  Hotkey=D
                  Researchhotkey=X
                  Buttonpos=2,1
                  Researchbuttonpos=1,2

                  [a0nq]
                  Tip=(|cffffcc00Q|r) Poison Touch - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Poison Touch - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Poison Touch - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Poison Touch - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Poison Touch - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [A10L]
                  Tip=(|cffffcc00W|r) Shallow Grave - [|cffffcc00Level 1|r],(|cffffcc00W|r) Shallow Grave - [|cffffcc00Level 2|r],(|cffffcc00W|r) Shallow Grave - [|cffffcc00Level 3|r],(|cffffcc00W|r) Shallow Grave - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Shallow Grave - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0or]
                  Tip=(|cffffcc00E|r) Shadow Wave - [|cffffcc00Level 1|r],(|cffffcc00E|r) Shadow Wave - [|cffffcc00Level 2|r],(|cffffcc00E|r) Shadow Wave - [|cffffcc00Level 3|r],(|cffffcc00E|r) Shadow Wave - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Shadow Wave - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [A10Q]
                  Tip=(|cffffcc00R|r) Weave - [|cffffcc00Level 1|r],(|cffffcc00R|r) Weave - [|cffffcc00Level 2|r],(|cffffcc00R|r) Weave - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Weave - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [A1db]
                  Tip=(|cffffcc00R|r) Weave (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Weave (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Weave (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Weave (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a010]
                  Tip=(|cffffcc00Q|r) Forked Lightning - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Forked Lightning - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Forked Lightning - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Forked Lightning - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Forked Lightning - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0rx]
                  Tip=(|cffffcc00W|r) Voodoo - [|cffffcc00Level 1|r],(|cffffcc00W|r) Voodoo - [|cffffcc00Level 2|r],(|cffffcc00W|r) Voodoo - [|cffffcc00Level 3|r],(|cffffcc00W|r) Voodoo - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Voodoo - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a00p]
                  Tip=(|cffffcc00E|r) Shackles - [|cffffcc00Level 1|r],(|cffffcc00E|r) Shackles - [|cffffcc00Level 2|r],(|cffffcc00E|r) Shackles - [|cffffcc00Level 3|r],(|cffffcc00E|r) Shackles - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Shackles - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a00h]
                  Tip=(|cffffcc00R|r) Mass Serpent Ward - [|cffffcc00Level 1|r],(|cffffcc00R|r) Mass Serpent Ward - [|cffffcc00Level 2|r],(|cffffcc00R|r) Mass Serpent Ward - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Mass Serpent Ward - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0a1]
                  Tip=(|cffffcc00R|r) Mass Serpent Ward (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Mass Serpent Ward (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Mass Serpent Ward (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Mass Serpent Ward (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a049]
                  Tip=(|cffffcc00Q|r) Laser - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Laser - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Laser - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Laser - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Laser - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a05e]
                  Tip=(|cffffcc00W|r) Heat Seeking Missle - [|cffffcc00Level 1|r],(|cffffcc00W|r) Heat Seeking Missle - [|cffffcc00Level 2|r],(|cffffcc00W|r) Heat Seeking Missle - [|cffffcc00Level 3|r],(|cffffcc00W|r) Heat Seeking Missle - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Heat Seeking Missle - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0bq]
                  Tip=(|cffffcc00E|r) March of the Machines - [|cffffcc00Level 1|r],(|cffffcc00E|r) March of the Machines - [|cffffcc00Level 2|r],(|cffffcc00E|r) March of the Machines - [|cffffcc00Level 3|r],(|cffffcc00E|r) March of the Machines - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn March of the Machines - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a065]
                  Tip=(|cffffcc00R|r) Rearm - [|cffffcc00Level 1|r],(|cffffcc00R|r) Rearm - [|cffffcc00Level 2|r],(|cffffcc00R|r) Rearm - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Rearm - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a06w]
                  Tip=(|cffffcc00Q|r) Split Earth - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Split Earth - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Split Earth - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Split Earth - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Split Earth - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [A035]
                  Tip=(|cffffcc00W|r) Diabolic Edict - [|cffffcc00Level 1|r],(|cffffcc00W|r) Diabolic Edict - [|cffffcc00Level 2|r],(|cffffcc00W|r) Diabolic Edict - [|cffffcc00Level 3|r],(|cffffcc00W|r) Diabolic Edict - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Diabolic Edict - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a06v]
                  Tip=(|cffffcc00E|r) Lightning Storm - [|cffffcc00Level 1|r],(|cffffcc00E|r) Lightning Storm - [|cffffcc00Level 2|r],(|cffffcc00E|r) Lightning Storm - [|cffffcc00Level 3|r],(|cffffcc00E|r) Lightning Storm - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Lightning Storm - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [A21F]
                  Tip=(|cffffcc00R|r) Activate Pulse Nova - [|cffffcc00Level 1|r],(|cffffcc00R|r) Activate Pulse Nova - [|cffffcc00Level 2|r],(|cffffcc00R|r) Activate Pulse Nova - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Activate Pulse Nova - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [A21H]
                  Tip=(|cffffcc00R|r) Deactivate Pulse Nova - [|cffffcc00Level 1|r],(|cffffcc00R|r) Deactivate Pulse Nova - [|cffffcc00Level 2|r],(|cffffcc00R|r) Deactivate Pulse Nova - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Deactivate Pulse Nova - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [A21G]
                  Tip=(|cffffcc00R|r) Activate Pulse Nova - [|cffffcc00Level 1|r],(|cffffcc00R|r) Activate Pulse Nova - [|cffffcc00Level 2|r],(|cffffcc00R|r) Activate Pulse Nova - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Activate Pulse Nova - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0o7]
                  Tip=(|cffffcc00Q|r) Dual Breath - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Dual Breath - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Dual Breath - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Dual Breath - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Dual Breath - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0o6]
                  Tip=(|cffffcc00W|r) Ice Path - [|cffffcc00Level 1|r],(|cffffcc00W|r) Ice Path - [|cffffcc00Level 2|r],(|cffffcc00W|r) Ice Path - [|cffffcc00Level 3|r],(|cffffcc00W|r) Ice Path - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Ice Path - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0o8]
                  Tip=Auto Fire - [|cffffcc00Level 1|r],Auto Fire - [|cffffcc00Level 2|r],Auto Fire - [|cffffcc00Level 3|r],Auto Fire - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Auto Fire - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0o5]
                  Tip=(|cffffcc00R|r) Macropyre - [|cffffcc00Level 1|r],(|cffffcc00R|r) Macropyre - [|cffffcc00Level 2|r],(|cffffcc00R|r) Macropyre - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Macropyre - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1b1]
                  Tip=(|cffffcc00R|r) Macropyre (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Macropyre (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Macropyre (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Macropyre (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [A2BE]
                  Tip=(|cffffcc00Q|r) Arcane Bolt - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Arcane Bolt - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Arcane Bolt - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Arcane Bolt - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Arcane Bolt - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [A2IT]
                  Tip=(|cffffcc00W|r) Concussive Shot - [|cffffcc00Level 1|r],(|cffffcc00W|r) Concussive Shot - [|cffffcc00Level 2|r],(|cffffcc00W|r) Concussive Shot - [|cffffcc00Level 3|r],(|cffffcc00W|r) Concussive Shot - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Concussive Shot - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [A2HN]
                  Tip=(|cffffcc00E|r) Ancient Seal - [|cffffcc00Level 1|r],(|cffffcc00E|r) Ancient Seal - [|cffffcc00Level 2|r],(|cffffcc00E|r) Ancient Seal - [|cffffcc00Level 3|r],(|cffffcc00E|r) Ancient Seal - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Ancient Seal - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [A2BG]
                  Tip=(|cffffcc00R|r) Mystic Flare - [|cffffcc00Level 1|r],(|cffffcc00R|r) Mystic Flare - [|cffffcc00Level 2|r],(|cffffcc00R|r) Mystic Flare - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Mystic Flare - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0nm]
                  Tip=(|cffffcc00Q|r) Paralyzing Cask - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Paralyzing Cask - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Paralyzing Cask - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Paralyzing Cask - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Paralyzing Cask - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0ne]
                  Tip=(|cffffcc00W|r) Voodoo Restoration - [|cffffcc00Level 1|r],(|cffffcc00W|r) Voodoo Restoration - [|cffffcc00Level 2|r],(|cffffcc00W|r) Voodoo Restoration - [|cffffcc00Level 3|r],(|cffffcc00W|r) Voodoo Restoration - [|cffffcc00Level 4|r]
                  UnTip=(|cffffcc00W|r) Deactivate Voodoo Restoration - [|cffffcc00Level 1|r],(|cffffcc00W|r) Deactivate Voodoo Restoration - [|cffffcc00Level 2|r],(|cffffcc00W|r) Deactivate Voodoo Restoration - [|cffffcc00Level 3|r],(|cffffcc00W|r) Deactivate Voodoo Restoration - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Voodoo Restoration - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Unhotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0no]
                  Tip=(|cffffcc00E|r) Maledict - [|cffffcc00Level 1|r],(|cffffcc00E|r) Maledict - [|cffffcc00Level 2|r],(|cffffcc00E|r) Maledict - [|cffffcc00Level 3|r],(|cffffcc00E|r) Maledict - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Maledict - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0nt]
                  Tip=(|cffffcc00R|r) Death Ward - [|cffffcc00Level 1|r],(|cffffcc00R|r) Death Ward - [|cffffcc00Level 2|r],(|cffffcc00R|r) Death Ward - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Death Ward - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0nx]
                  Tip=(|cffffcc00R|r) Death Ward (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Death Ward (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Death Ward (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Death Ward (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1mg]
                  Tip=(|cffffcc00Q|r) Cold Feet - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Cold Feet - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Cold Feet - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Cold Feet - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Cold Feet - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a1hs]
                  Tip=(|cffffcc00W|r) Ice Vortex - [|cffffcc00Level 1|r],(|cffffcc00W|r) Ice Vortex - [|cffffcc00Level 2|r],(|cffffcc00W|r) Ice Vortex - [|cffffcc00Level 3|r],(|cffffcc00W|r) Ice Vortex - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Ice Vortex - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a1hq]
                  Tip=(|cffffcc00E|r) Chilling Touch - [|cffffcc00Level 1|r],(|cffffcc00E|r) Chilling Touch - [|cffffcc00Level 2|r],(|cffffcc00E|r) Chilling Touch - [|cffffcc00Level 3|r],(|cffffcc00E|r) Chilling Touch - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Chilling Touch - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a1mi]
                  Tip=(|cffffcc00R|r) Ice Blast - [|cffffcc00Level 1|r],(|cffffcc00R|r) Ice Blast - [|cffffcc00Level 2|r],(|cffffcc00R|r) Ice Blast - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Ice Blast - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1mn]
                  Tip=(|cffffcc00R|r) Ice Blast - activate
                  Hotkey=R
                  Buttonpos=3,0

                  [A2NE]
                  Tip=(|cffffcc00Q|r) Arctic Burn - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Arctic Burn - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Arctic Burn - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Arctic Burn - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Arctic Burn - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [A2LA]
                  Tip=(|cffffcc00W|r) Splinter Blast - [|cffffcc00Level 1|r],(|cffffcc00W|r) Splinter Blast - [|cffffcc00Level 2|r],(|cffffcc00W|r) Splinter Blast - [|cffffcc00Level 3|r],(|cffffcc00W|r) Splinter Blast - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Splinter Blast - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [A2LB]
                  Tip=(|cffffcc00E|r) Cold Embrace - [|cffffcc00Level 1|r],(|cffffcc00E|r) Cold Embrace - [|cffffcc00Level 2|r],(|cffffcc00E|r) Cold Embrace - [|cffffcc00Level 3|r],(|cffffcc00E|r) Cold Embrace - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Cold Embrace - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [A0Z0]
                  Tip=(|cffffcc00R|r) Winter's Curse - [|cffffcc00Level 1|r],(|cffffcc00R|r) Winter's Curse - [|cffffcc00Level 2|r],(|cffffcc00R|r) Winter's Curse - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Winter's Curse - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a2oi]
                  Tip=(|cffffcc00Q|r) Enfeeble - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Enfeeble - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Enfeeble - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Enfeeble - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Enfeeble - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0gk]
                  Tip=(|cffffcc00W|r) Brain Sap - [|cffffcc00Level 1|r],(|cffffcc00W|r) Brain Sap - [|cffffcc00Level 2|r],(|cffffcc00W|r) Brain Sap - [|cffffcc00Level 3|r],(|cffffcc00W|r) Brain Sap - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Brain Sap - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a04y]
                  Tip=(|cffffcc00E|r) Nightmare - [|cffffcc00Level 1|r],(|cffffcc00E|r) Nightmare - [|cffffcc00Level 2|r],(|cffffcc00E|r) Nightmare - [|cffffcc00Level 3|r],(|cffffcc00E|r) Nightmare - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Nightmare - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a2o9]
                  Tip=(|cffffcc00E|r) End Nightmare
                  Hotkey=E
                  Buttonpos=2,0

                  [a02q]
                  Tip=(|cffffcc00R|r) Fiend's Grip - [|cffffcc00Level 1|r],(|cffffcc00R|r) Fiend's Grip - [|cffffcc00Level 2|r],(|cffffcc00R|r) Fiend's Grip - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Fiend's Grip - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1d9]
                  Tip=(|cffffcc00R|r) Fiend's Grip (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Fiend's Grip (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Fiend's Grip (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Fiend's Grip (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0qe]
                  Tip=(|cffffcc00Q|r) Vacuum - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Vacuum - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Vacuum - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Vacuum - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Vacuum - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0qg]
                  Tip=(|cffffcc00W|r) Ion Shell - [|cffffcc00Level 1|r],(|cffffcc00W|r) Ion Shell - [|cffffcc00Level 2|r],(|cffffcc00W|r) Ion Shell - [|cffffcc00Level 3|r],(|cffffcc00W|r) Ion Shell - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Ion Shell - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0r7]
                  Tip=(|cffffcc00E|r) Surge - [|cffffcc00Level 1|r],(|cffffcc00E|r) Surge - [|cffffcc00Level 2|r],(|cffffcc00E|r) Surge - [|cffffcc00Level 3|r],(|cffffcc00E|r) Surge - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Surge - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0qk]
                  Tip=(|cffffcc00R|r) Wall of Replica - [|cffffcc00Level 1|r],(|cffffcc00R|r) Wall of Replica - [|cffffcc00Level 2|r],(|cffffcc00R|r) Wall of Replica - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Wall of Replica - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [A21Q]
                  Tip=(|cffffcc00R|r) Wall of Replica - [|cffffcc00Level 1|r],(|cffffcc00R|r) Wall of Replica - [|cffffcc00Level 2|r],(|cffffcc00R|r) Wall of Replica - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Wall of Replica - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a02m]
                  Tip=(|cffffcc00Q|r) Carrion Swarm - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Carrion Swarm - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Carrion Swarm - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Carrion Swarm - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Carrion Swarm - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a06n]
                  Tip=(|cffffcc00Q|r) Carrion Swarm - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Carrion Swarm - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Carrion Swarm - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Carrion Swarm - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Carrion Swarm - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a072]
                  Tip=(|cffffcc00Q|r) Carrion Swarm - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Carrion Swarm - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Carrion Swarm - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Carrion Swarm - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Carrion Swarm - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a074]
                  Tip=(|cffffcc00Q|r) Carrion Swarm - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Carrion Swarm - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Carrion Swarm - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Carrion Swarm - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Carrion Swarm - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a078]
                  Tip=(|cffffcc00Q|r) Carrion Swarm - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Carrion Swarm - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Carrion Swarm - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Carrion Swarm - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Carrion Swarm - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0p6]
                  Tip=(|cffffcc00W|r) Silence - [|cffffcc00Level 1|r],(|cffffcc00W|r) Silence - [|cffffcc00Level 2|r],(|cffffcc00W|r) Silence - [|cffffcc00Level 3|r],(|cffffcc00W|r) Silence - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Silence - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a07h]
                  Tip=(|cffffcc00W|r) Silence - [|cffffcc00Level 1|r],(|cffffcc00W|r) Silence - [|cffffcc00Level 2|r],(|cffffcc00W|r) Silence - [|cffffcc00Level 3|r],(|cffffcc00W|r) Silence - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Silence - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a07i]
                  Tip=(|cffffcc00W|r) Silence - [|cffffcc00Level 1|r],(|cffffcc00W|r) Silence - [|cffffcc00Level 2|r],(|cffffcc00W|r) Silence - [|cffffcc00Level 3|r],(|cffffcc00W|r) Silence - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Silence - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a07j]
                  Tip=(|cffffcc00W|r) Silence - [|cffffcc00Level 1|r],(|cffffcc00W|r) Silence - [|cffffcc00Level 2|r],(|cffffcc00W|r) Silence - [|cffffcc00Level 3|r],(|cffffcc00W|r) Silence - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Silence - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a07m]
                  Tip=(|cffffcc00W|r) Silence - [|cffffcc00Level 1|r],(|cffffcc00W|r) Silence - [|cffffcc00Level 2|r],(|cffffcc00W|r) Silence - [|cffffcc00Level 3|r],(|cffffcc00W|r) Silence - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Silence - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a02c]
                  Tip=Witchcraft - [|cffffcc00Level 1|r],Witchcraft - [|cffffcc00Level 2|r],Witchcraft - [|cffffcc00Level 3|r],Witchcraft - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Witchcraft - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a073]
                  Tip=(|cffffcc00R|r) Exorcism - [|cffffcc00Level 1|r],(|cffffcc00R|r) Exorcism - [|cffffcc00Level 2|r],(|cffffcc00R|r) Exorcism - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Exorcism - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a03j]
                  Tip=(|cffffcc00R|r) Exorcism - [|cffffcc00Level 1|r],(|cffffcc00R|r) Exorcism - [|cffffcc00Level 2|r],(|cffffcc00R|r) Exorcism - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Exorcism - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a04j]
                  Tip=(|cffffcc00R|r) Exorcism - [|cffffcc00Level 1|r],(|cffffcc00R|r) Exorcism - [|cffffcc00Level 2|r],(|cffffcc00R|r) Exorcism - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Exorcism - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a04m]
                  Tip=(|cffffcc00R|r) Exorcism - [|cffffcc00Level 1|r],(|cffffcc00R|r) Exorcism - [|cffffcc00Level 2|r],(|cffffcc00R|r) Exorcism - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Exorcism - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a04n]
                  Tip=(|cffffcc00R|r) Exorcism - [|cffffcc00Level 1|r],(|cffffcc00R|r) Exorcism - [|cffffcc00Level 2|r],(|cffffcc00R|r) Exorcism - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Exorcism - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0x5]
                  Tip=(|cffffcc00Q|r) Impale - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Impale - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Impale - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Impale - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Impale - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0mn]
                  Tip=(|cffffcc00W|r) Voodoo - [|cffffcc00Level 1|r],(|cffffcc00W|r) Voodoo - [|cffffcc00Level 2|r],(|cffffcc00W|r) Voodoo - [|cffffcc00Level 3|r],(|cffffcc00W|r) Voodoo - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Voodoo - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a02n]
                  Tip=(|cffffcc00E|r) Mana Drain - [|cffffcc00Level 1|r],(|cffffcc00E|r) Mana Drain - [|cffffcc00Level 2|r],(|cffffcc00E|r) Mana Drain - [|cffffcc00Level 3|r],(|cffffcc00E|r) Mana Drain - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Mana Drain - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a095]
                  Tip=(|cffffcc00R|r) Finger of Death - [|cffffcc00Level 1|r],(|cffffcc00R|r) Finger of Death - [|cffffcc00Level 2|r],(|cffffcc00R|r) Finger of Death - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Finger of Death - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a09w]
                  Tip=(|cffffcc00R|r) Finger of Death (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Finger of Death (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Finger of Death (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Finger of Death (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0i7]
                  Tip=(|cffffcc00Q|r) Malefice - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Malefice - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Malefice - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Malefice - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Malefice - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [A180]
                  Tip=(|cffffcc00W|r) Demonic Conversion - [|cffffcc00Level 1|r],(|cffffcc00W|r) Demonic Conversion - [|cffffcc00Level 2|r],(|cffffcc00W|r) Demonic Conversion - [|cffffcc00Level 3|r],(|cffffcc00W|r) Demonic Conversion - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Demonic Conversion - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0b1]
                  Tip=(|cffffcc00E|r) Midnight Pulse - [|cffffcc00Level 1|r],(|cffffcc00E|r) Midnight Pulse - [|cffffcc00Level 2|r],(|cffffcc00E|r) Midnight Pulse - [|cffffcc00Level 3|r],(|cffffcc00E|r) Midnight Pulse - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Midnight Pulse - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a1bx]
                  Tip=(|cffffcc00R|r) Black Hole - [|cffffcc00Level 1|r],(|cffffcc00R|r) Black Hole - [|cffffcc00Level 2|r],(|cffffcc00R|r) Black Hole - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Black Hole - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a07f]
                  Tip=(|cffffcc00Q|r) Frost Nova - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Frost Nova - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Frost Nova - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Frost Nova - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Frost Nova - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a08r]
                  Tip=(|cffffcc00W|r) Frost Armor - [|cffffcc00Level 1|r],(|cffffcc00W|r) Frost Armor - [|cffffcc00Level 2|r],(|cffffcc00W|r) Frost Armor - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00W|r) Learn Frost Armor - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,0
                  Researchbuttonpos=1,0

                  [a053]
                  Tip=(|cffffcc00E|r) Dark Ritual - [|cffffcc00Level 1|r],(|cffffcc00E|r) Dark Ritual - [|cffffcc00Level 2|r],(|cffffcc00E|r) Dark Ritual - [|cffffcc00Level 3|r],(|cffffcc00E|r) Dark Ritual - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Dark Ritual - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a05t]
                  Tip=(|cffffcc00R|r) Chain Frost - [|cffffcc00Level 1|r],(|cffffcc00R|r) Chain Frost - [|cffffcc00Level 2|r],(|cffffcc00R|r) Chain Frost - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Chain Frost - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a08h]
                  Tip=(|cffffcc00R|r) Chain Frost (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Chain Frost (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Chain Frost (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Chain Frost (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a05v]
                  Tip=(|cffffcc00Q|r) Death Pulse - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Death Pulse - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Death Pulse - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Death Pulse - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Death Pulse - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [A01N]
                  Tip=Heartstopper Aura - [|cffffcc00Level 1|r],Heartstopper Aura - [|cffffcc00Level 2|r],Heartstopper Aura - [|cffffcc00Level 3|r],Heartstopper Aura - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Heartstopper Aura - [|cffffcc00Level %d|r]
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a060]
                  Tip=Sadist - [|cffffcc00Level 1|r],Sadist - [|cffffcc00Level 2|r],Sadist - [|cffffcc00Level 3|r],Sadist - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Sadist - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a067]
                  Tip=(|cffffcc00R|r) Reaper's Scythe - [|cffffcc00Level 1|r],(|cffffcc00R|r) Reaper's Scythe - [|cffffcc00Level 2|r],(|cffffcc00R|r) Reaper's Scythe - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Reaper's Scythe - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a08p]
                  Tip=(|cffffcc00R|r) Reaper's Scythe (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Reaper's Scythe (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Reaper's Scythe (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Reaper's Scythe (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0mt]
                  Tip=(|cffffcc00Q|r) Nether Blast - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Nether Blast - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Nether Blast - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Nether Blast - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Nether Blast - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0ce]
                  Tip=(|cffffcc00W|r) Decrepify - [|cffffcc00Level 1|r],(|cffffcc00W|r) Decrepify - [|cffffcc00Level 2|r],(|cffffcc00W|r) Decrepify - [|cffffcc00Level 3|r],(|cffffcc00W|r) Decrepify - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Decrepify - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a09d]
                  Tip=(|cffffcc00E|r) Nether Ward - [|cffffcc00Level 1|r],(|cffffcc00E|r) Nether Ward - [|cffffcc00Level 2|r],(|cffffcc00E|r) Nether Ward - [|cffffcc00Level 3|r],(|cffffcc00E|r) Nether Ward - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Nether Ward - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0cc]
                  Tip=(|cffffcc00R|r) Life Drain - [|cffffcc00Level 1|r],(|cffffcc00R|r) Life Drain - [|cffffcc00Level 2|r],(|cffffcc00R|r) Life Drain - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Life Drain - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a02z]
                  Tip=(|cffffcc00R|r) Life Drain (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Life Drain (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Life Drain (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Life Drain (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0oi]
                  Tip=(|cffffcc00Q|r) Arcane Orb - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Arcane Orb - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Arcane Orb - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00Q|r) Learn Arcane Orb - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0oj]
                  Tip=(|cffffcc00W|r) Astral Imprisonment - [|cffffcc00Level 1|r],(|cffffcc00W|r) Astral Imprisonment - [|cffffcc00Level 2|r],(|cffffcc00W|r) Astral Imprisonment - [|cffffcc00Level 3|r],(|cffffcc00W|r) Astral Imprisonment - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Astral Imprisonment - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0if]
                  Tip=Essence Aura - [|cffffcc00Level 1|r],Essence Aura - [|cffffcc00Level 2|r],Essence Aura - [|cffffcc00Level 3|r],Essence Aura - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Essence Aura - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0ok]
                  Tip=(|cffffcc00R|r) Sanity's Eclipse - [|cffffcc00Level 1|r],(|cffffcc00R|r) Sanity's Eclipse - [|cffffcc00Level 2|r],(|cffffcc00R|r) Sanity's Eclipse - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Sanity's Eclipse - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1VW]
                  Tip=(|cffffcc00R|r) Sanity's Eclipse (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Sanity's Eclipse (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Sanity's Eclipse (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Sanity's Eclipse (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0q7]
                  Tip=(|cffffcc00Q|r) Shadow Strike - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Shadow Strike - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Shadow Strike - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Shadow Strike - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Shadow Strike - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0me]
                  Tip=(|cffffcc00W|r) Blink - [|cffffcc00Level 1|r],(|cffffcc00W|r) Blink - [|cffffcc00Level 2|r],(|cffffcc00W|r) Blink - [|cffffcc00Level 3|r],(|cffffcc00W|r) Blink - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Blink - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a04a]
                  Tip=(|cffffcc00E|r) Scream of Pain - [|cffffcc00Level 1|r],(|cffffcc00E|r) Scream of Pain - [|cffffcc00Level 2|r],(|cffffcc00E|r) Scream of Pain - [|cffffcc00Level 3|r],(|cffffcc00E|r) Scream of Pain - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Scream of Pain - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [A28R]
                  Tip=(|cffffcc00R|r) Sonic Wave - [|cffffcc00Level 1|r],(|cffffcc00R|r) Sonic Wave - [|cffffcc00Level 2|r],(|cffffcc00R|r) Sonic Wave - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Sonic Wave - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [A28S]
                  Tip=(|cffffcc00R|r) Sonic Wave (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Sonic Wave (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Sonic Wave (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Sonic Wave (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0j5]
                  Tip=(|cffffcc00Q|r) Fatal Bonds - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Fatal Bonds - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Fatal Bonds - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Fatal Bonds - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Fatal Bonds - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0as]
                  Tip=(|cffffcc00W|r) Shadow Word - [|cffffcc00Level 1|r],(|cffffcc00W|r) Shadow Word - [|cffffcc00Level 2|r],(|cffffcc00W|r) Shadow Word - [|cffffcc00Level 3|r],(|cffffcc00W|r) Shadow Word - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Shadow Word - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a06p]
                  Tip=(|cffffcc00E|r) Upheaval - [|cffffcc00Level 1|r],(|cffffcc00E|r) Upheaval - [|cffffcc00Level 2|r],(|cffffcc00E|r) Upheaval - [|cffffcc00Level 3|r],(|cffffcc00E|r) Upheaval - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Upheaval - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [s008]
                  Tip=(|cffffcc00R|r) Rain of Chaos - [|cffffcc00Level 1|r],(|cffffcc00R|r) Rain of Chaos - [|cffffcc00Level 2|r],(|cffffcc00R|r) Rain of Chaos - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Rain of Chaos - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [s00U]
                  Tip=(|cffffcc00R|r) Rain of Chaos (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Rain of Chaos (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Rain of Chaos (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Rain of Chaos (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1s8]
                  Tip=(|cffffcc00Q|r) Disruption - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Disruption - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Disruption - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Disruption - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Disruption - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a1sb]
                  Tip=(|cffffcc00W|r) Soul Catcher - [|cffffcc00Level 1|r],(|cffffcc00W|r) Soul Catcher - [|cffffcc00Level 2|r],(|cffffcc00W|r) Soul Catcher - [|cffffcc00Level 3|r],(|cffffcc00W|r) Soul Catcher - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Soul Catcher - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a1s4]
                  Tip=(|cffffcc00E|r) Shadow Poison - [|cffffcc00Level 1|r],(|cffffcc00E|r) Shadow Poison - [|cffffcc00Level 2|r],(|cffffcc00E|r) Shadow Poison - [|cffffcc00Level 3|r],(|cffffcc00E|r) Shadow Poison - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Shadow Poison - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a1sa]
                  Tip=(|cffffcc00R|r) Demonic Purge - [|cffffcc00Level 1|r],(|cffffcc00R|r) Demonic Purge - [|cffffcc00Level 2|r],(|cffffcc00R|r) Demonic Purge - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Demonic Purge - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1s9]
                  Tip=(|cffffcc00D|r) Release Poison
                  Hotkey=D
                  Buttonpos=2,1

                  [A136]
                  Tip=(|cffffcc00Q|r) Torrent - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Torrent - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Torrent - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Torrent - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Torrent - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [A13T]
                  Tip=Tidebringer - [|cffffcc00Level 1|r],Tidebringer - [|cffffcc00Level 2|r],Tidebringer - [|cffffcc00Level 3|r],Tidebringer - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Tidebringer - [|cffffcc00Level %d|r]
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [A11N]
                  Tip=(|cffffcc00E|r) X Marks The Spot - [|cffffcc00Level 1|r],(|cffffcc00E|r) X Marks The Spot - [|cffffcc00Level 2|r],(|cffffcc00E|r) X Marks The Spot - [|cffffcc00Level 3|r],(|cffffcc00E|r) X Marks The Spot - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn X Marks The Spot - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [A13D]
                  Tip=(|cffffcc00E|r) X Marks The Spot Return
                  Hotkey=E
                  Buttonpos=2,0

                  [A11K]
                  Tip=(|cffffcc00R|r) Ghost Ship - [|cffffcc00Level 1|r],(|cffffcc00R|r) Ghost Ship - [|cffffcc00Level 2|r],(|cffffcc00R|r) Ghost Ship - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Ghost Ship - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0o1]
                  Tip=(|cffffcc00Q|r) Wild Axes - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Wild Axes - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Wild Axes - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Wild Axes - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Wild Axes - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0oo]
                  Tip=(|cffffcc00W|r) Call of the Wild - [|cffffcc00Level 1|r],(|cffffcc00W|r) Call of the Wild - [|cffffcc00Level 2|r],(|cffffcc00W|r) Call of the Wild - [|cffffcc00Level 3|r],(|cffffcc00W|r) Call of the Wild - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Call of the Wild - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0bd]
                  Tip=Inner Beast - [|cffffcc00Level 1|r],Inner Beast - [|cffffcc00Level 2|r],Inner Beast - [|cffffcc00Level 3|r],Inner Beast - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Inner Beast - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0o2]
                  Tip=(|cffffcc00R|r) Primal Roar - [|cffffcc00Level 1|r],(|cffffcc00R|r) Primal Roar - [|cffffcc00Level 2|r],(|cffffcc00R|r) Primal Roar - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Primal Roar - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [A289]
                  Tip=(|cffffcc00R|r) Primal Roar - [|cffffcc00Level 1|r],(|cffffcc00R|r) Primal Roar - [|cffffcc00Level 2|r],(|cffffcc00R|r) Primal Roar - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Primal Roar - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [A13Z]
                  Tip=(|cffffcc00R|r) Invisibility
                  Hotkey=R
                  Buttonpos=3,0

                  [a00s]
                  Tip=(|cffffcc00Q|r) Hoof Stomp - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Hoof Stomp - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Hoof Stomp - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Hoof Stomp - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Hoof Stomp - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a2on]
                  Tip=(|cffffcc00W|r) Double Edge - [|cffffcc00Level 1|r],(|cffffcc00W|r) Double Edge - [|cffffcc00Level 2|r],(|cffffcc00W|r) Double Edge - [|cffffcc00Level 3|r],(|cffffcc00W|r) Double Edge - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Double Edge - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a00v]
                  Tip=Return - [|cffffcc00Level 1|r],Return - [|cffffcc00Level 2|r],Return - [|cffffcc00Level 3|r],Return - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Return - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a2o6]
                  Tip=(|cffffcc00R|r) Stampede - [|cffffcc00Level 1|r],(|cffffcc00R|r) Stampede - [|cffffcc00Level 2|r],(|cffffcc00R|r) Stampede - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Stampede - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0sk]
                  Tip=(|cffffcc00Q|r) Fissure - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Fissure - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Fissure - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Fissure - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Fissure - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0dL]
                  Tip=(|cffffcc00W|r) Enchant Totem - [|cffffcc00Level 1|r],(|cffffcc00W|r) Enchant Totem - [|cffffcc00Level 2|r],(|cffffcc00W|r) Enchant Totem - [|cffffcc00Level 3|r],(|cffffcc00W|r) Enchant Totem - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Enchant Totem - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0dj]
                  Tip=Aftershock - [|cffffcc00Level 1|r],Aftershock - [|cffffcc00Level 2|r],Aftershock - [|cffffcc00Level 3|r],Aftershock - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Aftershock - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0dh]
                  Tip=(|cffffcc00R|r) Echo Slam - [|cffffcc00Level 1|r],(|cffffcc00R|r) Echo Slam - [|cffffcc00Level 2|r],(|cffffcc00R|r) Echo Slam - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Echo Slam - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1ob]
                  Tip=(|cffffcc00R|r) Echo Slam - [|cffffcc00Level 1|r],(|cffffcc00R|r) Echo Slam - [|cffffcc00Level 2|r],(|cffffcc00R|r) Echo Slam - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Echo Slam - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a08n]
                  Tip=(|cffffcc00Q|r) Purification - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Purification - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Purification - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Purification - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Purification - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a08v]
                  Tip=(|cffffcc00W|r) Repel - [|cffffcc00Level 1|r],(|cffffcc00W|r) Repel - [|cffffcc00Level 2|r],(|cffffcc00W|r) Repel - [|cffffcc00Level 3|r],(|cffffcc00W|r) Repel - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Repel - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a06a]
                  Tip=Degen Aura - [|cffffcc00Level 1|r],Degen Aura - [|cffffcc00Level 2|r],Degen Aura - [|cffffcc00Level 3|r],Degen Aura - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Degen Aura - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0er]
                  Tip=(|cffffcc00R|r) Guardian Angel - [|cffffcc00Level 1|r],(|cffffcc00R|r) Guardian Angel - [|cffffcc00Level 2|r],(|cffffcc00R|r) Guardian Angel - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Guardian Angel - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a06m]
                  Tip=(|cffffcc00Q|r) Thunder Clap - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Thunder Clap - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Thunder Clap - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Thunder Clap - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Thunder Clap - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0mx]
                  Tip=Drunken Brawler - [|cffffcc00Level 1|r],Drunken Brawler - [|cffffcc00Level 2|r],Drunken Brawler - [|cffffcc00Level 3|r],Drunken Brawler - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Drunken Brawler - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0mq]
                  Tip=(|cffffcc00R|r) Primal Split - [|cffffcc00Level 1|r],(|cffffcc00R|r) Primal Split - [|cffffcc00Level 2|r],(|cffffcc00R|r) Primal Split - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Primal Split - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1b6]
                  Tip=(|cffffcc00R|r) Primal Split - [|cffffcc00Level 1|r],(|cffffcc00R|r) Primal Split - [|cffffcc00Level 2|r],(|cffffcc00R|r) Primal Split - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Primal Split - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a190]
                  Tip=(|cffffcc00Q|r) Storm Bolt - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Storm Bolt - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Storm Bolt - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Storm Bolt - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Storm Bolt - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a01k]
                  Tip=Great Cleave - [|cffffcc00Level 1|r],Great Cleave - [|cffffcc00Level 2|r],Great Cleave - [|cffffcc00Level 3|r],Great Cleave - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Great Cleave - [|cffffcc00Level %d|r]
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [A2IS]
                  Tip=(|cffffcc00E|r) Warcry - [|cffffcc00Level 1|r],(|cffffcc00E|r) Warcry - [|cffffcc00Level 2|r],(|cffffcc00E|r) Warcry - [|cffffcc00Level 3|r],(|cffffcc00E|r) Warcry - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Warcry - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a1wh]
                  Tip=(|cffffcc00R|r) God Strength - [|cffffcc00Level 1|r],(|cffffcc00R|r) God Strength - [|cffffcc00Level 2|r],(|cffffcc00R|r) God Strength - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn God Strength - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0LL]
                  Tip=(|cffffcc00Q|r) Avalanche - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Avalanche - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Avalanche - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Avalanche - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Avalanche - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0bz]
                  Tip=(|cffffcc00W|r) Toss - [|cffffcc00Level 1|r],(|cffffcc00W|r) Toss - [|cffffcc00Level 2|r],(|cffffcc00W|r) Toss - [|cffffcc00Level 3|r],(|cffffcc00W|r) Toss - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Toss - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a19q]
                  Tip=Craggy Exterior - [|cffffcc00Level 1|r],Craggy Exterior - [|cffffcc00Level 2|r],Craggy Exterior - [|cffffcc00Level 3|r],Craggy Exterior - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Craggy Exterior - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0cy]
                  Tip=Grow - [|cffffcc00Level 1|r],Grow - [|cffffcc00Level 2|r],Grow - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Grow - [|cffffcc00Level %d|r]
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1VH]
                  Tip=(|cffffcc00D|r) War Club
                  Hotkey=D
                  Buttonpos=2,1

                  [a1aa]
                  Tip=(|cffffcc00Q|r) Echo Stomp - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Echo Stomp - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Echo Stomp - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Echo Stomp - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Echo Stomp - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a1a8]
                  Tip=(|cffffcc00W|r) Ancestral Spirit - [|cffffcc00Level 1|r],(|cffffcc00W|r) Ancestral Spirit - [|cffffcc00Level 2|r],(|cffffcc00W|r) Ancestral Spirit - [|cffffcc00Level 3|r],(|cffffcc00W|r) Ancestral Spirit - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Ancestral Spirit - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [A2NI]
                  Tip=(|cffffcc00W|r) End Ancestral Spirit - [|cffffcc00Level 1|r],(|cffffcc00W|r) End Ancestral Spirit - [|cffffcc00Level 2|r],(|cffffcc00W|r) End Ancestral Spirit - [|cffffcc00Level 3|r],(|cffffcc00W|r) End Ancestral Spirit - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn End Ancestral Spirit - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a1cd]
                  Tip=Natural Order - [|cffffcc00Level 1|r],Natural Order - [|cffffcc00Level 2|r],Natural Order - [|cffffcc00Level 3|r],Natural Order - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Natural Order - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a1a1]
                  Tip=(|cffffcc00R|r) Earth Splitter - [|cffffcc00Level 1|r],(|cffffcc00R|r) Earth Splitter - [|cffffcc00Level 2|r],(|cffffcc00R|r) Earth Splitter - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Earth Splitter - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [A2LK]
                  Tip=(|cffffcc00Q|r) Echo Stomp
                  Hotkey=Q
                  Buttonpos=0,0

                  [AETL]
                  Tip=Etheral
                  Buttonpos=2,0

                  [a01z]
                  Tip=(|cffffcc00Q|r) Nature's Guise - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Nature's Guise - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Nature's Guise - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Nature's Guise - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Nature's Guise - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [A26N]
                  Tip=(|cffffcc00W|r) Leech Seed - [|cffffcc00Level 1|r],(|cffffcc00W|r) Leech Seed - [|cffffcc00Level 2|r],(|cffffcc00W|r) Leech Seed - [|cffffcc00Level 3|r],(|cffffcc00W|r) Leech Seed - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Leech Seed - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [A2ML]
                  Tip=(|cffffcc00E|r) Living Armor - [|cffffcc00Level 1|r],(|cffffcc00E|r) Living Armor - [|cffffcc00Level 2|r],(|cffffcc00E|r) Living Armor - [|cffffcc00Level 3|r],(|cffffcc00E|r) Living Armor - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Living Armor - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a07z]
                  Tip=(|cffffcc00R|r) Overgrowth - [|cffffcc00Level 1|r],(|cffffcc00R|r) Overgrowth - [|cffffcc00Level 2|r],(|cffffcc00R|r) Overgrowth - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Overgrowth - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1ta]
                  Tip=(|cffffcc00Q|r) Tether - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Tether - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Tether - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Tether - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Tether - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a1tu]
                  Tip=(|cffffcc00Y|r) End Tether
                  Hotkey=Y
                  Buttonpos=0,2

                  [a1t8]
                  Tip=(|cffffcc00W|r) Spirits - [|cffffcc00Level 1|r],(|cffffcc00W|r) Spirits - [|cffffcc00Level 2|r],(|cffffcc00W|r) Spirits - [|cffffcc00Level 3|r],(|cffffcc00W|r) Spirits - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Spirits - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [A28Q]
                  Tip=(|cffffcc00R|r) Overcharge - [|cffffcc00Level 1|r],(|cffffcc00R|r) Overcharge - [|cffffcc00Level 2|r],(|cffffcc00R|r) Overcharge - [|cffffcc00Level 3|r],(|cffffcc00R|r) Overcharge - [|cffffcc00Level 4|r]
                  UnTip=(|cffffcc00C|r) Deactivate Overcharge - [|cffffcc00Level 1|r],(|cffffcc00C|r) Deactivate Overcharge - [|cffffcc00Level 2|r],(|cffffcc00C|r) Deactivate Overcharge - [|cffffcc00Level 3|r],(|cffffcc00C|r) Deactivate Overcharge - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Overcharge - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Unhotkey=C
                  Researchhotkey=E
                  Buttonpos=3,0
                  Unbuttonpos=2,2
                  Researchbuttonpos=2,0

                  [a1tb]
                  Tip=(|cffffcc00R|r) Relocate - [|cffffcc00Level 1|r],(|cffffcc00R|r) Relocate - [|cffffcc00Level 2|r],(|cffffcc00R|r) Relocate - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Relocate - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [A24B]
                  Tip=(|cffffcc00E|r) Pull Out
                  Hotkey=E
                  Buttonpos=2,0

                  [A24A]
                  Tip=(|cffffcc00D|r) Pull In
                  Hotkey=D
                  Buttonpos=2,1

                  [A1RJ]
                  Tip=(|cffffcc00Y|r) Icarus Dive - [|cffffcc00Level 1|r],(|cffffcc00Y|r) Icarus Dive - [|cffffcc00Level 2|r],(|cffffcc00Y|r) Icarus Dive - [|cffffcc00Level 3|r],(|cffffcc00Y|r) Icarus Dive - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Icarus Dive - [|cffffcc00Level %d|r]
                  Hotkey=Y
                  Researchhotkey=Q
                  Buttonpos=0,2
                  Researchbuttonpos=0,0

                  [A1YX]
                  Tip=(|cffffcc00X|r) Fire Spirits - [|cffffcc00Level 1|r],(|cffffcc00X|r) Fire Spirits - [|cffffcc00Level 2|r],(|cffffcc00X|r) Fire Spirits - [|cffffcc00Level 3|r],(|cffffcc00X|r) Fire Spirits - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Fire Spirits - [|cffffcc00Level %d|r]
                  Hotkey=X
                  Researchhotkey=W
                  Buttonpos=1,2
                  Researchbuttonpos=1,0

                  [A205]
                  Tip=(|cffffcc00D|r) Activate Sunray Movement
                  UnTip=(|cffffcc00D|r) Deactivate Sunray Movement
                  Hotkey=D
                  Unhotkey=D
                  Buttonpos=2,1
                  Unbuttonpos=2,1

                  [A1YY]
                  Tip=(|cffffcc00C|r) Sun Ray - [|cffffcc00Level 1|r],(|cffffcc00C|r) Sun Ray - [|cffffcc00Level 2|r],(|cffffcc00C|r) Sun Ray - [|cffffcc00Level 3|r],(|cffffcc00C|r) Sun Ray - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Sun Ray - [|cffffcc00Level %d|r]
                  Hotkey=C
                  Researchhotkey=E
                  Buttonpos=2,2
                  Researchbuttonpos=2,0

                  [A1RK]
                  Tip=(|cffffcc00V|r) Supernova - [|cffffcc00Level 1|r],(|cffffcc00V|r) Supernova - [|cffffcc00Level 2|r],(|cffffcc00V|r) Supernova - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Supernova - [|cffffcc00Level %d|r]
                  Hotkey=V
                  Researchhotkey=R
                  Buttonpos=3,2
                  Researchbuttonpos=3,0

                  [A20N]
                  Tip=(|cffffcc00Y|r) Icarus Dive
                  Hotkey=Y
                  Buttonpos=0,2

                  [A1Z2]
                  Tip=(|cffffcc00X|r) Target Fire Spirits
                  Hotkey=X
                  Buttonpos=1,2

                  [A1Z3]
                  Tip=(|cffffcc00C|r) Sun Ray
                  Hotkey=C
                  Buttonpos=2,2

                  [A2JB]
                  Tip=(|cffffcc00Y|r) Overwhelming Odds - [|cffffcc00Level 1|r],(|cffffcc00Y|r) Overwhelming Odds - [|cffffcc00Level 2|r],(|cffffcc00Y|r) Overwhelming Odds - [|cffffcc00Level 3|r],(|cffffcc00Y|r) Overwhelming Odds - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Overwhelming Odds - [|cffffcc00Level %d|r]
                  Hotkey=Y
                  Researchhotkey=Q
                  Buttonpos=0,2
                  Researchbuttonpos=0,0

                  [A2J2]
                  Tip=(|cffffcc00X|r) Press The Attack - [|cffffcc00Level 1|r],(|cffffcc00X|r) Press The Attack - [|cffffcc00Level 2|r],(|cffffcc00X|r) Press The Attack - [|cffffcc00Level 3|r],(|cffffcc00X|r) Press The Attack - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Press The Attack - [|cffffcc00Level %d|r]
                  Hotkey=X
                  Researchhotkey=W
                  Buttonpos=1,2
                  Researchbuttonpos=1,0

                  [A2EY]
                  Tip=Moment of Courage - [|cffffcc00Level 1|r],Moment of Courage - [|cffffcc00Level 2|r],Moment of Courage - [|cffffcc00Level 3|r],Moment of Courage - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Moment of Courage - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,2
                  Researchbuttonpos=2,0

                  [A2CI]
                  Tip=(|cffffcc00V|r) Duel - [|cffffcc00Level 1|r],(|cffffcc00V|r) Duel - [|cffffcc00Level 2|r],(|cffffcc00V|r) Duel - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Duel - [|cffffcc00Level %d|r]
                  Hotkey=V
                  Researchhotkey=R
                  Buttonpos=3,2
                  Researchbuttonpos=3,0

                  [A1YO]
                  Tip=(|cffffcc00Y|r) Ice Shards - [|cffffcc00Level 1|r],(|cffffcc00Y|r) Ice Shards - [|cffffcc00Level 2|r],(|cffffcc00Y|r) Ice Shards - [|cffffcc00Level 3|r],(|cffffcc00Y|r) Ice Shards - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Ice Shards - [|cffffcc00Level %d|r]
                  Hotkey=Y
                  Researchhotkey=Q
                  Buttonpos=0,2
                  Researchbuttonpos=0,0

                  [A1S7]
                  Tip=(|cffffcc00X|r) Snowball - [|cffffcc00Level 1|r],(|cffffcc00X|r) Snowball - [|cffffcc00Level 2|r],(|cffffcc00X|r) Snowball - [|cffffcc00Level 3|r],(|cffffcc00X|r) Snowball - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Snowball - [|cffffcc00Level %d|r]
                  Hotkey=X
                  Researchhotkey=W
                  Buttonpos=1,2
                  Researchbuttonpos=1,0

                  [A1YR]
                  Tip=(|cffffcc00C|r) Frozen Sigil - [|cffffcc00Level 1|r],(|cffffcc00C|r) Frozen Sigil - [|cffffcc00Level 2|r],(|cffffcc00C|r) Frozen Sigil - [|cffffcc00Level 3|r],(|cffffcc00C|r) Frozen Sigil - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Frozen Sigil - [|cffffcc00Level %d|r]
                  Hotkey=C
                  Researchhotkey=E
                  Buttonpos=2,2
                  Researchbuttonpos=2,0

                  [A1YQ]
                  Tip=(|cffffcc00V|r) Walrus Punch - [|cffffcc00Level 1|r],(|cffffcc00V|r) Walrus Punch - [|cffffcc00Level 2|r],(|cffffcc00V|r) Walrus Punch - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Walrus Punch - [|cffffcc00Level %d|r]
                  Hotkey=V
                  Researchhotkey=R
                  Buttonpos=3,2
                  Researchbuttonpos=3,0

                  [A2FK]
                  Tip=(|cffffcc00Y|r) Whirling Death - [|cffffcc00Level 1|r],(|cffffcc00Y|r) Whirling Death - [|cffffcc00Level 2|r],(|cffffcc00Y|r) Whirling Death - [|cffffcc00Level 3|r],(|cffffcc00Y|r) Whirling Death - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Whirling Death - [|cffffcc00Level %d|r]
                  Hotkey=Y
                  Researchhotkey=Q
                  Buttonpos=0,2
                  Researchbuttonpos=0,0

                  [A2E3]
                  Tip=(|cffffcc00X|r) Timber Chain - [|cffffcc00Level 1|r],(|cffffcc00X|r) Timber Chain - [|cffffcc00Level 2|r],(|cffffcc00X|r) Timber Chain - [|cffffcc00Level 3|r],(|cffffcc00X|r) Timber Chain - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Timber Chain - [|cffffcc00Level %d|r]
                  Hotkey=X
                  Researchhotkey=W
                  Buttonpos=1,2
                  Researchbuttonpos=1,0

                  [A2E4]
                  Tip=Reactive Armor - [|cffffcc00Level 1|r],Reactive Armor - [|cffffcc00Level 2|r],Reactive Armor - [|cffffcc00Level 3|r],Reactive Armor - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Reactive Armor - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,2
                  Researchbuttonpos=2,0

                  [A2E5]
                  Tip=(|cffffcc00V|r) Chakram - [|cffffcc00Level 1|r],(|cffffcc00V|r) Chakram - [|cffffcc00Level 2|r],(|cffffcc00V|r) Chakram - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Chakram - [|cffffcc00Level %d|r]
                  Hotkey=V
                  Researchhotkey=R
                  Buttonpos=3,2
                  Researchbuttonpos=3,0

                  [A2FX]
                  Tip=(|cffffcc00V|r) Return Chakram
                  Hotkey=V
                  Buttonpos=3,2

                  [a0il]
                  Tip=(|cffffcc00Q|r) Acid Spray - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Acid Spray - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Acid Spray - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Acid Spray - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Acid Spray - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0o3]
                  Tip=Goblin's Greed - [|cffffcc00Level 1|r],Goblin's Greed - [|cffffcc00Level 2|r],Goblin's Greed - [|cffffcc00Level 3|r],Goblin's Greed - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Goblin's Greed - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a1ni]
                  Tip=(|cffffcc00R|r) Unstable Concoction - [|cffffcc00Level 1|r],(|cffffcc00R|r) Unstable Concoction - [|cffffcc00Level 2|r],(|cffffcc00R|r) Unstable Concoction - [|cffffcc00Level 3|r],(|cffffcc00R|r) Unstable Concoction - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00R|r) Learn Unstable Concoction - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1nh]
                  Tip=(|cffffcc00R|r) Release Unstable Concoction
                  Hotkey=R
                  Buttonpos=3,0

                  [a0fw]
                  Tip=(|cffffcc00Y|r) Viscous Nasal Goo - [|cffffcc00Level 1|r],(|cffffcc00Y|r) Viscous Nasal Goo - [|cffffcc00Level 2|r],(|cffffcc00Y|r) Viscous Nasal Goo - [|cffffcc00Level 3|r],(|cffffcc00Y|r) Viscous Nasal Goo - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Viscous Nasal Goo - [|cffffcc00Level %d|r]
                  Hotkey=Y
                  Researchhotkey=Q
                  Buttonpos=0,2
                  Researchbuttonpos=0,0

                  [a0gp]
                  Tip=(|cffffcc00X|r) Quill Spray - [|cffffcc00Level 1|r],(|cffffcc00X|r) Quill Spray - [|cffffcc00Level 2|r],(|cffffcc00X|r) Quill Spray - [|cffffcc00Level 3|r],(|cffffcc00X|r) Quill Spray - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Quill Spray - [|cffffcc00Level %d|r]
                  Hotkey=X
                  Researchhotkey=W
                  Buttonpos=1,2
                  Researchbuttonpos=1,0

                  [a0m3]
                  Tip=Bristleback - [|cffffcc00Level 1|r],Bristleback - [|cffffcc00Level 2|r],Bristleback - [|cffffcc00Level 3|r],Bristleback - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Bristleback - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,2
                  Researchbuttonpos=2,0

                  [a0fv]
                  Tip=Warpath - [|cffffcc00Level 1|r],Warpath - [|cffffcc00Level 2|r],Warpath - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Warpath - [|cffffcc00Level %d|r]
                  Researchhotkey=R
                  Buttonpos=3,2
                  Researchbuttonpos=3,0

                  [a0z4]
                  Tip=(|cffffcc00Q|r) Battery Assault - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Battery Assault - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Battery Assault - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Battery Assault - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Battery Assault - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0z5]
                  Tip=(|cffffcc00W|r) Power Cog - [|cffffcc00Level 1|r],(|cffffcc00W|r) Power Cog - [|cffffcc00Level 2|r],(|cffffcc00W|r) Power Cog - [|cffffcc00Level 3|r],(|cffffcc00W|r) Power Cog - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Power Cog - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0z6]
                  Tip=(|cffffcc00E|r) Rocket Flare - [|cffffcc00Level 1|r],(|cffffcc00E|r) Rocket Flare - [|cffffcc00Level 2|r],(|cffffcc00E|r) Rocket Flare - [|cffffcc00Level 3|r],(|cffffcc00E|r) Rocket Flare - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Rocket Flare - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0z8]
                  Tip=(|cffffcc00R|r) Hookshot - [|cffffcc00Level 1|r],(|cffffcc00R|r) Hookshot - [|cffffcc00Level 2|r],(|cffffcc00R|r) Hookshot - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Hookshot - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1cv]
                  Tip=(|cffffcc00V|r) Hookshot (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00V|r) Hookshot (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00V|r) Hookshot (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Hookshot (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=V
                  Researchhotkey=R
                  Buttonpos=3,2
                  Researchbuttonpos=3,0

                  [a03f]
                  Tip=(|cffffcc00Y|r) Breathe Fire - [|cffffcc00Level 1|r],(|cffffcc00Y|r) Breathe Fire - [|cffffcc00Level 2|r],(|cffffcc00Y|r) Breathe Fire - [|cffffcc00Level 3|r],(|cffffcc00Y|r) Breathe Fire - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Breathe Fire - [|cffffcc00Level %d|r]
                  Hotkey=Y
                  Researchhotkey=Q
                  Buttonpos=0,2
                  Researchbuttonpos=0,0

                  [a0ar]
                  Tip=(|cffffcc00X|r) Dragon Tail - [|cffffcc00Level 1|r],(|cffffcc00X|r) Dragon Tail - [|cffffcc00Level 2|r],(|cffffcc00X|r) Dragon Tail - [|cffffcc00Level 3|r],(|cffffcc00X|r) Dragon Tail - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Dragon Tail - [|cffffcc00Level %d|r]
                  Hotkey=X
                  Researchhotkey=W
                  Buttonpos=1,2
                  Researchbuttonpos=1,0

                  [a0cL]
                  Tip=Dragon Blood - [|cffffcc00Level 1|r],Dragon Blood - [|cffffcc00Level 2|r],Dragon Blood - [|cffffcc00Level 3|r],Dragon Blood - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Dragon Blood - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,2
                  Researchbuttonpos=2,0

                  [a03g]
                  Tip=(|cffffcc00V|r) Elder Dragon Form - [|cffffcc00Level 1|r],(|cffffcc00V|r) Elder Dragon Form - [|cffffcc00Level 2|r],(|cffffcc00V|r) Elder Dragon Form - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Elder Dragon Form - [|cffffcc00Level %d|r]
                  Hotkey=V
                  Researchhotkey=R
                  Buttonpos=3,2
                  Researchbuttonpos=3,0

                  [a07d]
                  Tip=Corrosive Attack
                  Buttonpos=2,1

                  [a02s]
                  Tip=(|cffffcc00Q|r) Shockwave - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Shockwave - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Shockwave - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Shockwave - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Shockwave - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a037]
                  Tip=(|cffffcc00W|r) Empower - [|cffffcc00Level 1|r],(|cffffcc00W|r) Empower - [|cffffcc00Level 2|r],(|cffffcc00W|r) Empower - [|cffffcc00Level 3|r],(|cffffcc00W|r) Empower - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Empower - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a1rd]
                  Tip=(|cffffcc00E|r) Skewer - [|cffffcc00Level 1|r],(|cffffcc00E|r) Skewer - [|cffffcc00Level 2|r],(|cffffcc00E|r) Skewer - [|cffffcc00Level 3|r],(|cffffcc00E|r) Skewer - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Skewer - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [A29L]
                  Tip=(|cffffcc00R|r) Reverse Polarity - [|cffffcc00Level 1|r],(|cffffcc00R|r) Reverse Polarity - [|cffffcc00Level 2|r],(|cffffcc00R|r) Reverse Polarity - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Reverse Polarity - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0qp]
                  Tip=(|cffffcc00Y|r) Inner Vitality - [|cffffcc00Level 1|r],(|cffffcc00Y|r) Inner Vitality - [|cffffcc00Level 2|r],(|cffffcc00Y|r) Inner Vitality - [|cffffcc00Level 3|r],(|cffffcc00Y|r) Inner Vitality - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Inner Vitality - [|cffffcc00Level %d|r]
                  Hotkey=Y
                  Researchhotkey=Q
                  Buttonpos=0,2
                  Researchbuttonpos=0,0

                  [a0qn]
                  Tip=(|cffffcc00X|r) Burning Spear - [|cffffcc00Level 1|r],(|cffffcc00X|r) Burning Spear - [|cffffcc00Level 2|r],(|cffffcc00X|r) Burning Spear - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00W|r) Learn Burning Spear - [|cffffcc00Level %d|r]
                  Hotkey=X
                  Researchhotkey=W
                  Buttonpos=1,2
                  Unbuttonpos=1,2
                  Researchbuttonpos=1,0

                  [a0qq]
                  Tip=Berserker's Blood - [|cffffcc00Level 1|r],Berserker's Blood - [|cffffcc00Level 2|r],Berserker's Blood - [|cffffcc00Level 3|r],Berserker's Blood - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Berserker's Blood - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,2
                  Researchbuttonpos=2,0

                  [a0qr]
                  Tip=(|cffffcc00V|r) Life Break - [|cffffcc00Level 1|r],(|cffffcc00V|r) Life Break - [|cffffcc00Level 2|r],(|cffffcc00V|r) Life Break - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Life Break - [|cffffcc00Level %d|r]
                  Hotkey=V
                  Researchhotkey=R
                  Buttonpos=3,2
                  Researchbuttonpos=3,0

                  [a1b3]
                  Tip=(|cffffcc00V|r) Life Break (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00V|r) Life Break (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00V|r) Life Break (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Life Break (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=V
                  Researchhotkey=R
                  Buttonpos=3,2
                  Researchbuttonpos=3,0

                  [a06o]
                  Tip=(|cffffcc00Q|r) Burrowstrike - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Burrowstrike - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Burrowstrike - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Burrowstrike - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Burrowstrike - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0h0]
                  Tip=(|cffffcc00W|r) Sand Storm - [|cffffcc00Level 1|r],(|cffffcc00W|r) Sand Storm - [|cffffcc00Level 2|r],(|cffffcc00W|r) Sand Storm - [|cffffcc00Level 3|r],(|cffffcc00W|r) Sand Storm - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Sand Storm - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0fa]
                  Tip=Caustic Finale - [|cffffcc00Level 1|r],Caustic Finale - [|cffffcc00Level 2|r],Caustic Finale - [|cffffcc00Level 3|r],Caustic Finale - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Caustic Finale - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a06r]
                  Tip=(|cffffcc00R|r) Epicenter - [|cffffcc00Level 1|r],(|cffffcc00R|r) Epicenter - [|cffffcc00Level 2|r],(|cffffcc00R|r) Epicenter - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Epicenter - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1b4]
                  Tip=(|cffffcc00R|r) Epicenter (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Epicenter (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Epicenter (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Epicenter (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1p8]
                  Tip=(|cffffcc00Q|r) Charge of Darkness - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Charge of Darkness - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Charge of Darkness - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Charge of Darkness - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Charge of Darkness - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0es]
                  Tip=Empowering Haste - [|cffffcc00Level 1|r],Empowering Haste - [|cffffcc00Level 2|r],Empowering Haste - [|cffffcc00Level 3|r],Empowering Haste - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Empowering Haste - [|cffffcc00Level %d|r]
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0g5]
                  Tip=Greater Bash - [|cffffcc00Level 1|r],Greater Bash - [|cffffcc00Level 2|r],Greater Bash - [|cffffcc00Level 3|r],Greater Bash - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Greater Bash - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0g4]
                  Tip=(|cffffcc00R|r) Nether Strike - [|cffffcc00Level 1|r],(|cffffcc00R|r) Nether Strike - [|cffffcc00Level 2|r],(|cffffcc00R|r) Nether Strike - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Nether Strike - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1d8]
                  Tip=(|cffffcc00R|r) Nether Strike (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Nether Strike (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Nether Strike (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Nether Strike (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1vu]
                  Tip=(|cffffcc00Y|r) End Charge
                  Hotkey=Y
                  Buttonpos=0,2

                  [a046]
                  Tip=(|cffffcc00Q|r) Gush - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Gush - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Gush - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Gush - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Gush - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a04e]
                  Tip=Kraken Shell - [|cffffcc00Level 1|r],Kraken Shell - [|cffffcc00Level 2|r],Kraken Shell - [|cffffcc00Level 3|r],Kraken Shell - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Kraken Shell - [|cffffcc00Level %d|r]
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [A226]
                  Tip=(|cffffcc00E|r) Anchor Smash - [|cffffcc00Level 1|r],(|cffffcc00E|r) Anchor Smash - [|cffffcc00Level 2|r],(|cffffcc00E|r) Anchor Smash - [|cffffcc00Level 3|r],(|cffffcc00E|r) Anchor Smash - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Anchor Smash - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [A29I]
                  Tip=(|cffffcc00R|r) Ravage - [|cffffcc00Level 1|r],(|cffffcc00R|r) Ravage - [|cffffcc00Level 2|r],(|cffffcc00R|r) Ravage - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Ravage - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0i6]
                  Tip=(|cffffcc00Q|r) Berserker's Call - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Berserker's Call - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Berserker's Call - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Berserker's Call - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Berserker's Call - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0s1]
                  Tip=(|cffffcc00W|r) Battle Hunger - [|cffffcc00Level 1|r],(|cffffcc00W|r) Battle Hunger - [|cffffcc00Level 2|r],(|cffffcc00W|r) Battle Hunger - [|cffffcc00Level 3|r],(|cffffcc00W|r) Battle Hunger - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Battle Hunger - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0c6]
                  Tip=Counter Helix - [|cffffcc00Level 1|r],Counter Helix - [|cffffcc00Level 2|r],Counter Helix - [|cffffcc00Level 3|r],Counter Helix - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Counter Helix - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0e2]
                  Tip=(|cffffcc00R|r) Culling Blade - [|cffffcc00Level 1|r],(|cffffcc00R|r) Culling Blade - [|cffffcc00Level 2|r],(|cffffcc00R|r) Culling Blade - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Culling Blade - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1mr]
                  Tip=(|cffffcc00R|r) Culling Blade - Aghanim's - [|cffffcc00Level 1|r],(|cffffcc00R|r) Culling Blade - Aghanim's - [|cffffcc00Level 2|r],(|cffffcc00R|r) Culling Blade - Aghanim's - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Culling Blade - Aghanim's - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a055]
                  Tip=(|cffffcc00Q|r) Chaos Bolt - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Chaos Bolt - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Chaos Bolt - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Chaos Bolt - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Chaos Bolt - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0rw]
                  Tip=(|cffffcc00W|r) Reality Rift - [|cffffcc00Level 1|r],(|cffffcc00W|r) Reality Rift - [|cffffcc00Level 2|r],(|cffffcc00W|r) Reality Rift - [|cffffcc00Level 3|r],(|cffffcc00W|r) Reality Rift - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Reality Rift - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a03n]
                  Tip=Critical Strike - [|cffffcc00Level 1|r],Critical Strike - [|cffffcc00Level 2|r],Critical Strike - [|cffffcc00Level 3|r],Critical Strike - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Critical Strike - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a03o]
                  Tip=(|cffffcc00R|r) Phantasm - [|cffffcc00Level 1|r],(|cffffcc00R|r) Phantasm - [|cffffcc00Level 2|r],(|cffffcc00R|r) Phantasm - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Phantasm - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [A10R]
                  Tip=(|cffffcc00Q|r) Devour - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Devour - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Devour - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Devour - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Devour - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a1op]
                  Tip=(|cffffcc00W|r) Scorched Earth - [|cffffcc00Level 1|r],(|cffffcc00W|r) Scorched Earth - [|cffffcc00Level 2|r],(|cffffcc00W|r) Scorched Earth - [|cffffcc00Level 3|r],(|cffffcc00W|r) Scorched Earth - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Scorched Earth - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a094]
                  Tip=(|cffffcc00E|r) LVL? Death - [|cffffcc00Level 1|r],(|cffffcc00E|r) LVL? Death - [|cffffcc00Level 2|r],(|cffffcc00E|r) LVL? Death - [|cffffcc00Level 3|r],(|cffffcc00E|r) LVL? Death - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn LVL? Death - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0mu]
                  Tip=(|cffffcc00R|r) Doom - [|cffffcc00Level 1|r],(|cffffcc00R|r) Doom - [|cffffcc00Level 2|r],(|cffffcc00R|r) Doom - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Doom - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0a2]
                  Tip=(|cffffcc00R|r) Doom (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Doom (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Doom (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Doom (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1p0]
                  Tip=(|cffffcc00X|r) Stomp
                  Hotkey=X
                  Buttonpos=1,2

                  [s00n]
                  Tip=Endurance Aura
                  Buttonpos=2,1

                  [a1oq]
                  Tip=(|cffffcc00D|r) Chain Lightning
                  Hotkey=D
                  Buttonpos=2,1

                  [a1ov]
                  Tip=(|cffffcc00X|r) Shockwave
                  Hotkey=X
                  Buttonpos=1,2

                  [a1ow]
                  Tip=Unholy Aura
                  Buttonpos=2,1

                  [a1ot]
                  Tip=(|cffffcc00D|r) Mana Burn
                  Hotkey=D
                  Buttonpos=2,1

                  [a1ou]
                  Tip=(|cffffcc00D|r) Purge
                  Hotkey=D
                  Buttonpos=2,1

                  [a1p4]
                  Tip=(|cffffcc00X|r) Tornado
                  Hotkey=X
                  Buttonpos=1,2

                  [a1p3]
                  Tip=Toughness Aura
                  Buttonpos=2,1

                  [a1oz]
                  Tip=(|cffffcc00D|r) Heal
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=D
                  Buttonpos=2,1
                  Unbuttonpos=2,1

                  [a1os]
                  Tip=(|cffffcc00D|r) Clap
                  Hotkey=D
                  Buttonpos=2,1

                  [a1or]
                  Tip=(|cffffcc00D|r) Frost Armor
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=D
                  Buttonpos=2,1
                  Unbuttonpos=2,1

                  [a1p6]
                  Tip=(|cffffcc00X|r) Ensnare
                  Hotkey=X
                  Buttonpos=1,2

                  [a1p5]
                  Tip=(|cffffcc00D|r) Raise Skeletons
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=D
                  Buttonpos=2,1
                  Unbuttonpos=2,1

                  [a1pa]
                  Tip=Frost Attack
                  Buttonpos=2,1

                  [a1ox]
                  Tip=Command Aura
                  Buttonpos=1,2

                  [a1oy]
                  Tip=Critical Strike
                  Buttonpos=2,1

                  [s00m]
                  Tip=Speed Aura
                  Buttonpos=2,1

                  [a1p1]
                  Tip=Envenomed Weapons
                  Buttonpos=2,1

                  [a0t2]
                  Tip=(|cffffcc00Q|r) Rage - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Rage - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Rage - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Rage - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Rage - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0ss]
                  Tip=Feast - [|cffffcc00Level 1|r],Feast - [|cffffcc00Level 2|r],Feast - [|cffffcc00Level 3|r],Feast - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Feast - [|cffffcc00Level %d|r]
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a194]
                  Tip=(|cffffcc00E|r) Open Wounds - [|cffffcc00Level 1|r],(|cffffcc00E|r) Open Wounds - [|cffffcc00Level 2|r],(|cffffcc00E|r) Open Wounds - [|cffffcc00Level 3|r],(|cffffcc00E|r) Open Wounds - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Open Wounds - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0sw]
                  Tip=(|cffffcc00R|r) Infest - [|cffffcc00Level 1|r],(|cffffcc00R|r) Infest - [|cffffcc00Level 2|r],(|cffffcc00R|r) Infest - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Infest - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0sx]
                  Tip=(|cffffcc00R|r) Consume - [|cffffcc00Level 1|r],(|cffffcc00R|r) Consume - [|cffffcc00Level 2|r],(|cffffcc00R|r) Consume - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Consume - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0i3]
                  Tip=(|cffffcc00Q|r) Death Coil - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Death Coil - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Death Coil - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Death Coil - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Death Coil - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0mf]
                  Tip=(|cffffcc00W|r) Aphotic Shield - [|cffffcc00Level 1|r],(|cffffcc00W|r) Aphotic Shield - [|cffffcc00Level 2|r],(|cffffcc00W|r) Aphotic Shield - [|cffffcc00Level 3|r],(|cffffcc00W|r) Aphotic Shield - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Aphotic Shield - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0mg]
                  Tip=Frostmourne - [|cffffcc00Level 1|r],Frostmourne - [|cffffcc00Level 2|r],Frostmourne - [|cffffcc00Level 3|r],Frostmourne - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Frostmourne - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0ns]
                  Tip=(|cffffcc00R|r) Borrowed Time - [|cffffcc00Level 1|r],(|cffffcc00R|r) Borrowed Time - [|cffffcc00Level 2|r],(|cffffcc00R|r) Borrowed Time - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Borrowed Time - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1da]
                  Tip=(|cffffcc00R|r) Borrowed Time (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Borrowed Time (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Borrowed Time (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Borrowed Time (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a03d]
                  Tip=(|cffffcc00Q|r) Summon Wolves - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Summon Wolves - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Summon Wolves - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Summon Wolves - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Summon Wolves - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0zf]
                  Tip=(|cffffcc00W|r) Howl - [|cffffcc00Level 1|r],(|cffffcc00W|r) Howl - [|cffffcc00Level 2|r],(|cffffcc00W|r) Howl - [|cffffcc00Level 3|r],(|cffffcc00W|r) Howl - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Howl - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a03e]
                  Tip=Feral Heart - [|cffffcc00Level 1|r],Feral Heart - [|cffffcc00Level 2|r],Feral Heart - [|cffffcc00Level 3|r],Feral Heart - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Feral Heart - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a093]
                  Tip=(|cffffcc00R|r) Shapeshift - [|cffffcc00Level 1|r],(|cffffcc00R|r) Shapeshift - [|cffffcc00Level 2|r],(|cffffcc00R|r) Shapeshift - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Shapeshift - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a03b]
                  Tip=Critical Strike
                  Buttonpos=1,1

                  [a02h]
                  Tip=(|cffffcc00Q|r) Void - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Void - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Void - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Void - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Void - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a08c]
                  Tip=(|cffffcc00W|r) Crippling Fear - [|cffffcc00Level 1|r],(|cffffcc00W|r) Crippling Fear - [|cffffcc00Level 2|r],(|cffffcc00W|r) Crippling Fear - [|cffffcc00Level 3|r],(|cffffcc00W|r) Crippling Fear - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Crippling Fear - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a08e]
                  Tip=(|cffffcc00X|r) Crippling Fear - [|cffffcc00Level 1|r],(|cffffcc00X|r) Crippling Fear - [|cffffcc00Level 2|r],(|cffffcc00X|r) Crippling Fear - [|cffffcc00Level 3|r],(|cffffcc00X|r) Crippling Fear - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Crippling Fear - [|cffffcc00Level %d|r]
                  Hotkey=X
                  Researchhotkey=W
                  Buttonpos=1,2
                  Researchbuttonpos=1,0

                  [a086]
                  Tip=Hunter in the Night - [|cffffcc00Level 1|r],Hunter in the Night - [|cffffcc00Level 2|r],Hunter in the Night - [|cffffcc00Level 3|r],Hunter in the Night - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Hunter in the Night - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a03k]
                  Tip=(|cffffcc00R|r) Darkness - [|cffffcc00Level 1|r],(|cffffcc00R|r) Darkness - [|cffffcc00Level 2|r],(|cffffcc00R|r) Darkness - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Darkness - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1b0]
                  Tip=(|cffffcc00R|r) Darkness - [|cffffcc00Level 1|r],(|cffffcc00R|r) Darkness - [|cffffcc00Level 2|r],(|cffffcc00R|r) Darkness - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Darkness - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [A01I]
                  Tip=(|cffffcc00Q|r) FireStorm - [|cffffcc00Level 1|r],(|cffffcc00Q|r) FireStorm - [|cffffcc00Level 2|r],(|cffffcc00Q|r) FireStorm - [|cffffcc00Level 3|r],(|cffffcc00Q|r) FireStorm - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn FireStorm - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0ra]
                  Tip=(|cffffcc00W|r) Pit of Malice - [|cffffcc00Level 1|r],(|cffffcc00W|r) Pit of Malice - [|cffffcc00Level 2|r],(|cffffcc00W|r) Pit of Malice - [|cffffcc00Level 3|r],(|cffffcc00W|r) Pit of Malice - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Pit of Malice - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [AIcd]
                  Tip=Atrophy Aura - [|cffffcc00Level 1|r],Atrophy Aura - [|cffffcc00Level 2|r],Atrophy Aura - [|cffffcc00Level 3|r],Atrophy Aura - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Atrophy Aura - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0r0]
                  Tip=(|cffffcc00R|r) Dark Portal - [|cffffcc00Level 1|r],(|cffffcc00R|r) Dark Portal - [|cffffcc00Level 2|r],(|cffffcc00R|r) Dark Portal - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Dark Portal - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a06i]
                  Tip=(|cffffcc00Q|r) Meat Hook - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Meat Hook - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Meat Hook - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Meat Hook - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Meat Hook - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a06k]
                  Tip=(|cffffcc00W|r) Rot - [|cffffcc00Level 1|r],(|cffffcc00W|r) Rot - [|cffffcc00Level 2|r],(|cffffcc00W|r) Rot - [|cffffcc00Level 3|r],(|cffffcc00W|r) Rot - [|cffffcc00Level 4|r]
                  UnTip=(|cffffcc00W|r) Deactivate Rot - [|cffffcc00Level 1|r],(|cffffcc00W|r) Deactivate Rot - [|cffffcc00Level 2|r],(|cffffcc00W|r) Deactivate Rot - [|cffffcc00Level 3|r],(|cffffcc00W|r) Deactivate Rot - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Rot - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Unhotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,0
                  Researchbuttonpos=1,0

                  [a06d]
                  Tip=Flesh Heap - [|cffffcc00Level 1|r],Flesh Heap - [|cffffcc00Level 2|r],Flesh Heap - [|cffffcc00Level 3|r],Flesh Heap - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Flesh Heap - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0fL]
                  Tip=(|cffffcc00R|r) Dismember - [|cffffcc00Level 1|r],(|cffffcc00R|r) Dismember - [|cffffcc00Level 2|r],(|cffffcc00R|r) Dismember - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Dismember - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1cx]
                  Tip=(|cffffcc00R|r) Dismember (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Dismember (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Dismember (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Dismember (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a01y]
                  Tip=Reincarnation - [|cffffcc00Level 1|r],Reincarnation - [|cffffcc00Level 2|r],Reincarnation - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Reincarnation - [|cffffcc00Level %d|r]
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a05c]
                  Tip=(|cffffcc00Q|r) Sprint - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Sprint - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Sprint - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Sprint - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Sprint - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [A29K]
                  Tip=(|cffffcc00W|r) Slithereen Crush - [|cffffcc00Level 1|r],(|cffffcc00W|r) Slithereen Crush - [|cffffcc00Level 2|r],(|cffffcc00W|r) Slithereen Crush - [|cffffcc00Level 3|r],(|cffffcc00W|r) Slithereen Crush - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Slithereen Crush - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0jj]
                  Tip=Bash - [|cffffcc00Level 1|r],Bash - [|cffffcc00Level 2|r],Bash - [|cffffcc00Level 3|r],Bash - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Bash - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a034]
                  Tip=(|cffffcc00R|r) Amplify Damage - [|cffffcc00Level 1|r],(|cffffcc00R|r) Amplify Damage - [|cffffcc00Level 2|r],(|cffffcc00R|r) Amplify Damage - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00R|r) Learn Amplify Damage - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Unbuttonpos=3,0
                  Researchbuttonpos=3,0

                  [A15S]
                  Tip=(|cffffcc00Q|r) Decay - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Decay - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Decay - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Decay - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Decay - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0r5]
                  Tip=(|cffffcc00W|r) Soul Rip - [|cffffcc00Level 1|r],(|cffffcc00W|r) Soul Rip - [|cffffcc00Level 2|r],(|cffffcc00W|r) Soul Rip - [|cffffcc00Level 3|r],(|cffffcc00W|r) Soul Rip - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Soul Rip - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [A15V]
                  Tip=(|cffffcc00E|r) Tombstone - [|cffffcc00Level 1|r],(|cffffcc00E|r) Tombstone - [|cffffcc00Level 2|r],(|cffffcc00E|r) Tombstone - [|cffffcc00Level 3|r],(|cffffcc00E|r) Tombstone - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Tombstone - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [A15J]
                  Tip=(|cffffcc00R|r) Flesh Golem - [|cffffcc00Level 1|r],(|cffffcc00R|r) Flesh Golem - [|cffffcc00Level 2|r],(|cffffcc00R|r) Flesh Golem - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Flesh Golem - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [A15K]
                  Tip=Plague - [|cffffcc00Level 1|r],Plague - [|cffffcc00Level 2|r],Plague - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00Y|r) Learn Plague - [|cffffcc00Level %d|r]
                  Researchhotkey=Y
                  Buttonpos=2,1
                  Researchbuttonpos=0,2

                  [a022]
                  Tip=Mana Break - [|cffffcc00Level 1|r],Mana Break - [|cffffcc00Level 2|r],Mana Break - [|cffffcc00Level 3|r],Mana Break - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Mana Break - [|cffffcc00Level %d|r]
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0ky]
                  Tip=Spell Shield - [|cffffcc00Level 1|r],Spell Shield - [|cffffcc00Level 2|r],Spell Shield - [|cffffcc00Level 3|r],Spell Shield - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Spell Shield - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0e3]
                  Tip=(|cffffcc00R|r) Mana Void - [|cffffcc00Level 1|r],(|cffffcc00R|r) Mana Void - [|cffffcc00Level 2|r],(|cffffcc00R|r) Mana Void - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Mana Void - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a064]
                  Tip=(|cffffcc00Q|r) Scatter Shot - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Scatter Shot - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Scatter Shot - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Scatter Shot - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Scatter Shot - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a03S]
                  Tip=Headshot - [|cffffcc00Level 1|r],Headshot - [|cffffcc00Level 2|r],Headshot - [|cffffcc00Level 3|r],Headshot - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Headshot - [|cffffcc00Level %d|r]
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a03U]
                  Tip=Take Aim - [|cffffcc00Level 1|r],Take Aim - [|cffffcc00Level 2|r],Take Aim - [|cffffcc00Level 3|r],Take Aim - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Take Aim - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a04P]
                  Tip=(|cffffcc00R|r) Assassinate - [|cffffcc00Level 1|r],(|cffffcc00R|r) Assassinate - [|cffffcc00Level 2|r],(|cffffcc00R|r) Assassinate - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Assassinate - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a05g]
                  Tip=(|cffffcc00Q|r) Blade Fury - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Blade Fury - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Blade Fury - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Blade Fury - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Blade Fury - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a047]
                  Tip=(|cffffcc00W|r) Healing Ward - [|cffffcc00Level 1|r],(|cffffcc00W|r) Healing Ward - [|cffffcc00Level 2|r],(|cffffcc00W|r) Healing Ward - [|cffffcc00Level 3|r],(|cffffcc00W|r) Healing Ward - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Healing Ward - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a00k]
                  Tip=Blade Dance - [|cffffcc00Level 1|r],Blade Dance - [|cffffcc00Level 2|r],Blade Dance - [|cffffcc00Level 3|r],Blade Dance - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Blade Dance - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0m1]
                  Tip=(|cffffcc00R|r) Omnislash - [|cffffcc00Level 1|r],(|cffffcc00R|r) Omnislash - [|cffffcc00Level 2|r],(|cffffcc00R|r) Omnislash - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Omnislash - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1ax]
                  Tip=(|cffffcc00R|r) Omnislash (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Omnislash (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Omnislash (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Omnislash (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0a5]
                  Tip=(|cffffcc00Q|r) Summon Spirit Bear - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Summon Spirit Bear - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Summon Spirit Bear - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Summon Spirit Bear - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Summon Spirit Bear - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a1ef]
                  Tip=(|cffffcc00W|r) Rabid - [|cffffcc00Level 1|r],(|cffffcc00W|r) Rabid - [|cffffcc00Level 2|r],(|cffffcc00W|r) Rabid - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00W|r) Learn Rabid - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,2
                  Researchbuttonpos=1,0

                  [a1ee]
                  Tip=(|cffffcc00W|r) Rabid - [|cffffcc00Level 1|r],(|cffffcc00W|r) Rabid - [|cffffcc00Level 2|r],(|cffffcc00W|r) Rabid - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00W|r) Learn Rabid - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,2
                  Researchbuttonpos=1,0

                  [a1eh]
                  Tip=(|cffffcc00W|r) Rabid - [|cffffcc00Level 1|r],(|cffffcc00W|r) Rabid - [|cffffcc00Level 2|r],(|cffffcc00W|r) Rabid - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00W|r) Learn Rabid - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,2
                  Researchbuttonpos=1,0

                  [a1ei]
                  Tip=(|cffffcc00W|r) Rabid - [|cffffcc00Level 1|r],(|cffffcc00W|r) Rabid - [|cffffcc00Level 2|r],(|cffffcc00W|r) Rabid - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00W|r) Learn Rabid - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,2
                  Researchbuttonpos=1,0

                  [a1eg]
                  Tip=(|cffffcc00W|r) Rabid - [|cffffcc00Level 1|r],(|cffffcc00W|r) Rabid - [|cffffcc00Level 2|r],(|cffffcc00W|r) Rabid - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00W|r) Learn Rabid - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,2
                  Researchbuttonpos=1,0

                  [a0a8]
                  Tip=Synergy - [|cffffcc00Level 1|r],Synergy - [|cffffcc00Level 2|r],Synergy - [|cffffcc00Level 3|r],Synergy - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Synergy - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0ag]
                  Tip=(|cffffcc00R|r) True Form - [|cffffcc00Level 1|r],(|cffffcc00R|r) True Form - [|cffffcc00Level 2|r],(|cffffcc00R|r) True Form - [|cffffcc00Level 3|r]
                  UnTip=(|cffffcc00R|r) Lone Druid Form
                  Researchtip=(|cffffcc00R|r) Learn True Form - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Unhotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Unbuttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1ec]
                  Tip=(|cffffcc00D|r) Battle Cry
                  Hotkey=D
                  Buttonpos=2,1

                  [a1ed]
                  Tip=(|cffffcc00D|r) Battle Cry
                  Hotkey=D
                  Buttonpos=2,1

                  [a0ai]
                  Tip=(|cffffcc00D|r) Battle Cry
                  Hotkey=D
                  Buttonpos=2,1

                  [a0a0]
                  Tip=Entangle
                  Buttonpos=0,0

                  [a0a7]
                  Tip=(|cffffcc00R|r) Return
                  Hotkey=R
                  Buttonpos=3,0

                  [a0ah]
                  Tip=Demolish
                  Buttonpos=2,0

                  [a042]
                  Tip=(|cffffcc00Q|r) Lucent Beam - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Lucent Beam - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Lucent Beam - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Lucent Beam - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Lucent Beam - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a041]
                  Tip=Moon Glaive - [|cffffcc00Level 1|r],Moon Glaive - [|cffffcc00Level 2|r],Moon Glaive - [|cffffcc00Level 3|r],Moon Glaive - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Moon Glaive - [|cffffcc00Level %d|r]
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a062]
                  Tip=Lunar Blessing - [|cffffcc00Level 1|r],Lunar Blessing - [|cffffcc00Level 2|r],Lunar Blessing - [|cffffcc00Level 3|r],Lunar Blessing - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Lunar Blessing - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a054]
                  Tip=(|cffffcc00R|r) Eclipse - [|cffffcc00Level 1|r],(|cffffcc00R|r) Eclipse - [|cffffcc00Level 2|r],(|cffffcc00R|r) Eclipse - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Eclipse - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a00u]
                  Tip=(|cffffcc00R|r) Eclipse (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Eclipse (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Eclipse (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Eclipse (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0fn]
                  Tip=(|cffffcc00Q|r) Waveform - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Waveform - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Waveform - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Waveform - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Waveform - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0g6]
                  Tip=(|cffffcc00W|r) Adaptive Strike - [|cffffcc00Level 1|r],(|cffffcc00W|r) Adaptive Strike - [|cffffcc00Level 2|r],(|cffffcc00W|r) Adaptive Strike - [|cffffcc00Level 3|r],(|cffffcc00W|r) Adaptive Strike - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Adaptive Strike - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0kx]
                  Tip=(|cffffcc00E|r) Agility Morph - [|cffffcc00Level 1|r],(|cffffcc00E|r) Agility Morph - [|cffffcc00Level 2|r],(|cffffcc00E|r) Agility Morph - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00E|r) Learn Morph - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Unbuttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0kw]
                  Tip=(|cffffcc00D|r) Strength Morph - [|cffffcc00Level 1|r],trength Morph - [|cffffcc00Level 2|r],trength Morph - [|cffffcc00Level 3|r],trength Morph - [|cffffcc00Level 4|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=D
                  Buttonpos=2,1
                  Unbuttonpos=2,1

                  [a0g8]
                  Tip=(|cffffcc00R|r) Replicate - [|cffffcc00Level 1|r],(|cffffcc00R|r) Replicate - [|cffffcc00Level 2|r],(|cffffcc00R|r) Replicate - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Replicate - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0gc]
                  Tip=(|cffffcc00R|r) Morph Replicate - [|cffffcc00Level 1|r],(|cffffcc00R|r) Morph Replicate - [|cffffcc00Level 2|r],(|cffffcc00R|r) Morph Replicate - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Morph Replicate - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a063]
                  Tip=(|cffffcc00Q|r) Mirror Image - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Mirror Image - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Mirror Image - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Mirror Image - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Mirror Image - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [A24D]
                  Tip=(|cffffcc00W|r) Ensnare - [|cffffcc00Level 1|r],(|cffffcc00W|r) Ensnare - [|cffffcc00Level 2|r],(|cffffcc00W|r) Ensnare - [|cffffcc00Level 3|r],(|cffffcc00W|r) Ensnare - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Ensnare - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [A2KU]
                  Tip=(|cffffcc00E|r) Rip Tide - [|cffffcc00Level 1|r],(|cffffcc00E|r) Rip Tide - [|cffffcc00Level 2|r],(|cffffcc00E|r) Rip Tide - [|cffffcc00Level 3|r],(|cffffcc00E|r) Rip Tide - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Rip Tide - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [A07U]
                  Tip=(|cffffcc00R|r) Song of the Siren - [|cffffcc00Level 1|r],(|cffffcc00R|r) Song of the Siren - [|cffffcc00Level 2|r],(|cffffcc00R|r) Song of the Siren - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Song of the Siren - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [A24E]
                  Tip=(|cffffcc00V|r) Song of the Siren End - [|cffffcc00Level 1|r],(|cffffcc00V|r) Song of the Siren End - [|cffffcc00Level 2|r],(|cffffcc00V|r) Song of the Siren End - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Song of the Siren End - [|cffffcc00Level %d|r]
                  Hotkey=V
                  Researchhotkey=R
                  Buttonpos=3,2
                  Researchbuttonpos=3,0

                  [A10D]
                  Tip=(|cffffcc00Q|r) Spirit Lance - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Spirit Lance - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Spirit Lance - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Spirit Lance - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Spirit Lance - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0d7]
                  Tip=(|cffffcc00W|r) Doppelwalk - [|cffffcc00Level 1|r],(|cffffcc00W|r) Doppelwalk - [|cffffcc00Level 2|r],(|cffffcc00W|r) Doppelwalk - [|cffffcc00Level 3|r],(|cffffcc00W|r) Doppelwalk - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Doppelwalk - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0db]
                  Tip=Juxtapose - [|cffffcc00Level 1|r],Juxtapose - [|cffffcc00Level 2|r],Juxtapose - [|cffffcc00Level 3|r],Juxtapose - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Juxtapose - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0yk]
                  Tip=Phantom Edge - [|cffffcc00Level 1|r],Phantom Edge - [|cffffcc00Level 2|r],Phantom Edge - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Phantom Edge - [|cffffcc00Level %d|r]
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0kv]
                  Tip=(|cffffcc00Q|r) Starfall - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Starfall - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Starfall - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Starfall - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Starfall - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0L8]
                  Tip=(|cffffcc00W|r) Elune's Arrow - [|cffffcc00Level 1|r],(|cffffcc00W|r) Elune's Arrow - [|cffffcc00Level 2|r],(|cffffcc00W|r) Elune's Arrow - [|cffffcc00Level 3|r],(|cffffcc00W|r) Elune's Arrow - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Elune's Arrow - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0Ln]
                  Tip=(|cffffcc00E|r) Leap - [|cffffcc00Level 1|r],(|cffffcc00E|r) Leap - [|cffffcc00Level 2|r],(|cffffcc00E|r) Leap - [|cffffcc00Level 3|r],(|cffffcc00E|r) Leap - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Leap - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0ku]
                  Tip=(|cffffcc00R|r) Moonlight Shadow - [|cffffcc00Level 1|r],(|cffffcc00R|r) Moonlight Shadow - [|cffffcc00Level 2|r],(|cffffcc00R|r) Moonlight Shadow - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Moonlight Shadow - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0rg]
                  Tip=(|cffffcc00Q|r) Smoke Screen - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Smoke Screen - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Smoke Screen - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Smoke Screen - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Smoke Screen - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0k9]
                  Tip=(|cffffcc00W|r) Blink Strike - [|cffffcc00Level 1|r],(|cffffcc00W|r) Blink Strike - [|cffffcc00Level 2|r],(|cffffcc00W|r) Blink Strike - [|cffffcc00Level 3|r],(|cffffcc00W|r) Blink Strike - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Blink Strike - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0dz]
                  Tip=Backstab - [|cffffcc00Level 1|r],Backstab - [|cffffcc00Level 2|r],Backstab - [|cffffcc00Level 3|r],Backstab - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Backstab - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0mb]
                  Tip=Permanent Invisibility - [|cffffcc00Level 1|r],Permanent Invisibility - [|cffffcc00Level 2|r],Permanent Invisibility - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Permanent Invisibility - [|cffffcc00Level %d|r]
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a00j]
                  Tip=Permanent Invisibility - [|cffffcc00Level 1|r],Permanent Invisibility - [|cffffcc00Level 2|r],Permanent Invisibility - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Permanent Invisibility - [|cffffcc00Level %d|r]
                  Researchhotkey=R
                  Buttonpos=3,2
                  Researchbuttonpos=3,0

                  [a0be]
                  Tip=(|cffffcc00Q|r) Berserker Rage - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Berserker Rage - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Berserker Rage - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Berserker Rage - [|cffffcc00Level 4|r]
                  UnTip=(|cffffcc00Q|r) Ranged Form - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Ranged Form - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Ranged Form - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Ranged Form - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Berserker Rage - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Unhotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0
                  Researchbuttonpos=0,0

                  [a09e]
                  Tip=Bash
                  Buttonpos=2,1

                  [A21M]
                  Tip=(|cffffcc00W|r) Whirling Axes
                  Hotkey=W
                  Buttonpos=1,0

                  [A21N]
                  Tip=(|cffffcc00W|r) Whirling Axes
                  Hotkey=W
                  Buttonpos=1,0

                  [A21L]
                  Tip=(|cffffcc00X|r) Whirling Axes - [|cffffcc00Level 1|r],(|cffffcc00X|r) Whirling Axes - [|cffffcc00Level 2|r],(|cffffcc00X|r) Whirling Axes - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00W|r) Learn Whirling Axes - [|cffffcc00Level %d|r]
                  Hotkey=X
                  Researchhotkey=W
                  Buttonpos=1,2
                  Researchbuttonpos=1,0

                  [a0o0]
                  Tip=Fervor - [|cffffcc00Level 1|r],Fervor - [|cffffcc00Level 2|r],Fervor - [|cffffcc00Level 3|r],Fervor - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Fervor - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a1ej]
                  Tip=(|cffffcc00R|r) Rampage - [|cffffcc00Level 1|r],(|cffffcc00R|r) Rampage - [|cffffcc00Level 2|r],(|cffffcc00R|r) Rampage - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Rampage - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1so]
                  Tip=(|cffffcc00Q|r) Rocket Barrage - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Rocket Barrage - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Rocket Barrage - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Rocket Barrage - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Rocket Barrage - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a1sq]
                  Tip=(|cffffcc00W|r) Homing Missile - [|cffffcc00Level 1|r],(|cffffcc00W|r) Homing Missile - [|cffffcc00Level 2|r],(|cffffcc00W|r) Homing Missile - [|cffffcc00Level 3|r],(|cffffcc00W|r) Homing Missile - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Homing Missile - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a1tx]
                  Tip=(|cffffcc00E|r) Flak Cannon - [|cffffcc00Level 1|r],(|cffffcc00E|r) Flak Cannon - [|cffffcc00Level 2|r],(|cffffcc00E|r) Flak Cannon - [|cffffcc00Level 3|r],(|cffffcc00E|r) Flak Cannon - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Flak Cannon - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a1t5]
                  Tip=(|cffffcc00R|r) Call Down - [|cffffcc00Level 1|r],(|cffffcc00R|r) Call Down - [|cffffcc00Level 2|r],(|cffffcc00R|r) Call Down - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Call Down - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [A235]
                  Tip=(|cffffcc00R|r) Call Down - [|cffffcc00Level 1|r],(|cffffcc00R|r) Call Down - [|cffffcc00Level 2|r],(|cffffcc00R|r) Call Down - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Call Down - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a004]
                  Tip=(|cffffcc00Q|r) Shuriken Toss - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Shuriken Toss - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Shuriken Toss - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Shuriken Toss - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Shuriken Toss - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a1iq]
                  Tip=Jinada - [|cffffcc00Level 1|r],Jinada - [|cffffcc00Level 2|r],Jinada - [|cffffcc00Level 3|r],Jinada - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Jinada - [|cffffcc00Level %d|r]
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a07a]
                  Tip=(|cffffcc00E|r) Wind Walk - [|cffffcc00Level 1|r],(|cffffcc00E|r) Wind Walk - [|cffffcc00Level 2|r],(|cffffcc00E|r) Wind Walk - [|cffffcc00Level 3|r],(|cffffcc00E|r) Wind Walk - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Wind Walk - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0b4]
                  Tip=(|cffffcc00R|r) Track - [|cffffcc00Level 1|r],(|cffffcc00R|r) Track - [|cffffcc00Level 2|r],(|cffffcc00R|r) Track - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00R|r) Learn Track - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Unbuttonpos=3,0
                  Researchbuttonpos=3,0

                  [a026]
                  Tip=(|cffffcc00Q|r) Frost Arrows - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Frost Arrows - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Frost Arrows - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00Q|r) Learn Frost Arrows - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0qb]
                  Tip=(|cffffcc00W|r) Silence - [|cffffcc00Level 1|r],(|cffffcc00W|r) Silence - [|cffffcc00Level 2|r],(|cffffcc00W|r) Silence - [|cffffcc00Level 3|r],(|cffffcc00W|r) Silence - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Silence - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a029]
                  Tip=Trueshot Aura - [|cffffcc00Level 1|r],Trueshot Aura - [|cffffcc00Level 2|r],Trueshot Aura - [|cffffcc00Level 3|r],Trueshot Aura - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Trueshot Aura - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0vc]
                  Tip=Marksmanship - [|cffffcc00Level 1|r],Marksmanship - [|cffffcc00Level 2|r],Marksmanship - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Marksmanship - [|cffffcc00Level %d|r]
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0Lk]
                  Tip=(|cffffcc00Q|r) Time Walk - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Time Walk - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Time Walk - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Time Walk - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Time Walk - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0cz]
                  Tip=Backtrack - [|cffffcc00Level 1|r],Backtrack - [|cffffcc00Level 2|r],Backtrack - [|cffffcc00Level 3|r],Backtrack - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Backtrack - [|cffffcc00Level %d|r]
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a081]
                  Tip=Time Lock - [|cffffcc00Level 1|r],Time Lock - [|cffffcc00Level 2|r],Time Lock - [|cffffcc00Level 3|r],Time Lock - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Time Lock - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0j1]
                  Tip=(|cffffcc00R|r) Chronosphere - [|cffffcc00Level 1|r],(|cffffcc00R|r) Chronosphere - [|cffffcc00Level 2|r],(|cffffcc00R|r) Chronosphere - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Chronosphere - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1d7]
                  Tip=(|cffffcc00R|r) Chronosphere (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Chronosphere (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Chronosphere (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Chronosphere (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0nb]
                  Tip=(|cffffcc00Q|r) Earthbind - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Earthbind - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Earthbind - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Earthbind - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Earthbind - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0n8]
                  Tip=(|cffffcc00W|r) Poof - [|cffffcc00Level 1|r],(|cffffcc00W|r) Poof - [|cffffcc00Level 2|r],(|cffffcc00W|r) Poof - [|cffffcc00Level 3|r],(|cffffcc00W|r) Poof - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Poof - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0n7]
                  Tip=Geostrike - [|cffffcc00Level 1|r],Geostrike - [|cffffcc00Level 2|r],Geostrike - [|cffffcc00Level 3|r],Geostrike - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Geostrike - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0mw]
                  Tip=Divided We Stand - [|cffffcc00Level 1|r],Divided We Stand - [|cffffcc00Level 2|r],Divided We Stand - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Divided We Stand - [|cffffcc00Level %d|r]
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [A27C]
                  Tip=Divided We Stand - [|cffffcc00Level 1|r],Divided We Stand - [|cffffcc00Level 2|r],Divided We Stand - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Divided We Stand - [|cffffcc00Level %d|r]
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1e7]
                  Tip=(|cffffcc00Q|r) Plasma Field - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Plasma Field - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Plasma Field - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Plasma Field - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Plasma Field - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a1dp]
                  Tip=(|cffffcc00W|r) Static Link - [|cffffcc00Level 1|r],(|cffffcc00W|r) Static Link - [|cffffcc00Level 2|r],(|cffffcc00W|r) Static Link - [|cffffcc00Level 3|r],(|cffffcc00W|r) Static Link - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Static Link - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a1e6]
                  Tip=Unstable Current - [|cffffcc00Level 1|r],Unstable Current - [|cffffcc00Level 2|r],Unstable Current - [|cffffcc00Level 3|r],Unstable Current - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Unstable Current - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [A1ao]
                  Tip=(|cffffcc00R|r) Eye of the Storm - [|cffffcc00Level 1|r],(|cffffcc00R|r) Eye of the Storm - [|cffffcc00Level 2|r],(|cffffcc00R|r) Eye of the Storm - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Eye of the Storm - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [A1UV]
                  Tip=(|cffffcc00R|r) Eye of the Storm (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Eye of the Storm (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Eye of the Storm (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Eye of the Storm (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1c0]
                  Tip=(|cffffcc00Q|r) Split Shot - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Split Shot - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Split Shot - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Split Shot - [|cffffcc00Level 4|r]
                  UnTip=(|cffffcc00Q|r) Stop Split Shot - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Stop Split Shot - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Stop Split Shot - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Stop Split Shot - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Split Shot - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Unhotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0g2]
                  Tip=(|cffffcc00W|r) Mystic Snake - [|cffffcc00Level 1|r],(|cffffcc00W|r) Mystic Snake - [|cffffcc00Level 2|r],(|cffffcc00W|r) Mystic Snake - [|cffffcc00Level 3|r],(|cffffcc00W|r) Mystic Snake - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Mystic Snake - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0mp]
                  Tip=(|cffffcc00E|r) Activate Mana Shield - [|cffffcc00Level 1|r],(|cffffcc00E|r) Activate Mana Shield - [|cffffcc00Level 2|r],(|cffffcc00E|r) Activate Mana Shield - [|cffffcc00Level 3|r],(|cffffcc00E|r) Activate Mana Shield - [|cffffcc00Level 4|r]
                  UnTip=(|cffffcc00E|r) Deactivate Mana Shield - [|cffffcc00Level 1|r],(|cffffcc00E|r) Deactivate Mana Shield - [|cffffcc00Level 2|r],(|cffffcc00E|r) Deactivate Mana Shield - [|cffffcc00Level 3|r],(|cffffcc00E|r) Deactivate Mana Shield - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Activate Mana Shield - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Unhotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Unbuttonpos=2,0
                  Researchbuttonpos=2,0

                  [a1at]
                  Tip=(|cffffcc00R|r) Stone Gaze - [|cffffcc00Level 1|r],(|cffffcc00R|r) Stone Gaze - [|cffffcc00Level 2|r],(|cffffcc00R|r) Stone Gaze - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Stone Gaze - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a09j]
                  Tip=Split Shot
                  Buttonpos=2,1

                  [a1ea]
                  Tip=(|cffffcc00Q|r) Refraction - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Refraction - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Refraction - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Refraction - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Refraction - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0rv]
                  Tip=(|cffffcc00W|r) Meld - [|cffffcc00Level 1|r],(|cffffcc00W|r) Meld - [|cffffcc00Level 2|r],(|cffffcc00W|r) Meld - [|cffffcc00Level 3|r],(|cffffcc00W|r) Meld - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Meld - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0ro]
                  Tip=Psi Blades - [|cffffcc00Level 1|r],Psi Blades - [|cffffcc00Level 2|r],Psi Blades - [|cffffcc00Level 3|r],Psi Blades - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Psi Blades - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0rp]
                  Tip=(|cffffcc00R|r) Psionic Trap - [|cffffcc00Level 1|r],(|cffffcc00R|r) Psionic Trap - [|cffffcc00Level 2|r],(|cffffcc00R|r) Psionic Trap - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Psionic Trap - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0rt]
                  Tip=(|cffffcc00D|r) Trap
                  Hotkey=D
                  Buttonpos=2,1

                  [a0rq]
                  Tip=(|cffffcc00Y|r) Trap
                  Hotkey=Y
                  Buttonpos=0,2

                  [A2H3]
                  Tip=(|cffffcc00Q|r) Searing Chains - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Searing Chains - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Searing Chains - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Searing Chains - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Searing Chains - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [A2H0]
                  Tip=(|cffffcc00W|r) Sleight of Fist - [|cffffcc00Level 1|r],(|cffffcc00W|r) Sleight of Fist - [|cffffcc00Level 2|r],(|cffffcc00W|r) Sleight of Fist - [|cffffcc00Level 3|r],(|cffffcc00W|r) Sleight of Fist - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Sleight of Fist - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [A2JL]
                  Tip=(|cffffcc00D|r) Fire Remnant - [|cffffcc00Level 1|r],(|cffffcc00D|r) Fire Remnant - [|cffffcc00Level 2|r],(|cffffcc00D|r) Fire Remnant - [|cffffcc00Level 3|r],(|cffffcc00D|r) Fire Remnant - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00|r)
                  Hotkey=D
                  Researchhotkey=
                  Buttonpos=2,1
                  Researchbuttonpos=,

                  [A2HS]
                  Tip=(|cffffcc00E|r) Flame Guard - [|cffffcc00Level 1|r],(|cffffcc00E|r) Flame Guard - [|cffffcc00Level 2|r],(|cffffcc00E|r) Flame Guard - [|cffffcc00Level 3|r],(|cffffcc00E|r) Flame Guard - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Flame Guard - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [A2JR]
                  Tip=(|cffffcc00R|r) Fire Remnant - [|cffffcc00Level 1|r],(|cffffcc00R|r) Fire Remnant - [|cffffcc00Level 2|r],(|cffffcc00R|r) Fire Remnant - [|cffffcc00Level 3|r],(|cffffcc00R|r) Fire Remnant - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00|r)
                  Hotkey=R
                  Researchhotkey=
                  Buttonpos=3,0
                  Researchbuttonpos=,

                  [A2JP]
                  Tip=(|cffffcc00R|r) Fire Remnant - [|cffffcc00Level 1|r],(|cffffcc00R|r) Fire Remnant - [|cffffcc00Level 2|r],(|cffffcc00R|r) Fire Remnant - [|cffffcc00Level 3|r],(|cffffcc00R|r) Fire Remnant - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00|r)
                  Hotkey=R
                  Researchhotkey=
                  Buttonpos=3,0
                  Researchbuttonpos=,

                  [A2JQ]
                  Tip=(|cffffcc00R|r) Fire Remnant - [|cffffcc00Level 1|r],(|cffffcc00R|r) Fire Remnant - [|cffffcc00Level 2|r],(|cffffcc00R|r) Fire Remnant - [|cffffcc00Level 3|r],(|cffffcc00R|r) Fire Remnant - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00|r)
                  Hotkey=R
                  Researchhotkey=
                  Buttonpos=3,0
                  Researchbuttonpos=,

                  [A2JO]
                  Tip=(|cffffcc00R|r) Fire Remnant - [|cffffcc00Level 1|r],(|cffffcc00R|r) Fire Remnant - [|cffffcc00Level 2|r],(|cffffcc00R|r) Fire Remnant - [|cffffcc00Level 3|r],(|cffffcc00R|r) Fire Remnant - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00|r)
                  Hotkey=R
                  Researchhotkey=
                  Buttonpos=3,0
                  Researchbuttonpos=,

                  [A2JK]
                  Tip=(|cffffcc00V|r) Fire Remnant - [|cffffcc00Level 1|r],(|cffffcc00V|r) Fire Remnant - [|cffffcc00Level 2|r],(|cffffcc00V|r) Fire Remnant - [|cffffcc00Level 3|r],(|cffffcc00V|r) Fire Remnant - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00R|r) Learn Fire Remnant - [|cffffcc00Level %d|r]
                  Hotkey=V
                  Researchhotkey=R
                  Buttonpos=3,2
                  Researchbuttonpos=3,0

                  [a03y]
                  Tip=(|cffffcc00Q|r) Earthshock - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Earthshock - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Earthshock - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Earthshock - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Earthshock - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [A1N4]
                  Tip=(|cffffcc00W|r) Overpower - [|cffffcc00Level 1|r],(|cffffcc00W|r) Overpower - [|cffffcc00Level 2|r],(|cffffcc00W|r) Overpower - [|cffffcc00Level 3|r],(|cffffcc00W|r) Overpower - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Overpower - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [anic]
                  Tip=Fury Swipes - [|cffffcc00Level 1|r],Fury Swipes - [|cffffcc00Level 2|r],Fury Swipes - [|cffffcc00Level 3|r],Fury Swipes - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Fury Swipes - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0Lc]
                  Tip=(|cffffcc00R|r) Enrage - [|cffffcc00Level 1|r],(|cffffcc00R|r) Enrage - [|cffffcc00Level 2|r],(|cffffcc00R|r) Enrage - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Enrage - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a02a]
                  Tip=(|cffffcc00Q|r) Magic Missle - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Magic Missle - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Magic Missle - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Magic Missle - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Magic Missle - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a17o]
                  Tip=(|cffffcc00E|r) Wave of Terror - [|cffffcc00Level 1|r],(|cffffcc00E|r) Wave of Terror - [|cffffcc00Level 2|r],(|cffffcc00E|r) Wave of Terror - [|cffffcc00Level 3|r],(|cffffcc00E|r) Wave of Terror - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Wave of Terror - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=W
                  Buttonpos=2,0
                  Researchbuttonpos=1,0

                  [acac]
                  Tip=Command Aura - [|cffffcc00Level 1|r],Command Aura - [|cffffcc00Level 2|r],Command Aura - [|cffffcc00Level 3|r],Command Aura - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Command Aura - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=1,0
                  Researchbuttonpos=2,0

                  [a0in]
                  Tip=(|cffffcc00R|r) Nether Swap - [|cffffcc00Level 1|r],(|cffffcc00R|r) Nether Swap - [|cffffcc00Level 2|r],(|cffffcc00R|r) Nether Swap - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Nether Swap - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1aw]
                  Tip=(|cffffcc00R|r) Nether Swap (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Nether Swap (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Nether Swap (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Nether Swap (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1im]
                  Tip=(|cffffcc00Q|r) Dark Pact - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Dark Pact - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Dark Pact - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Dark Pact - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Dark Pact - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a1j7]
                  Tip=(|cffffcc00W|r) Pounce - [|cffffcc00Level 1|r],(|cffffcc00W|r) Pounce - [|cffffcc00Level 2|r],(|cffffcc00W|r) Pounce - [|cffffcc00Level 3|r],(|cffffcc00W|r) Pounce - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Pounce - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a1hr]
                  Tip=Essence Shift - [|cffffcc00Level 1|r],Essence Shift - [|cffffcc00Level 2|r],Essence Shift - [|cffffcc00Level 3|r],Essence Shift - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Essence Shift - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a1in]
                  Tip=(|cffffcc00R|r) Shadow Dance - [|cffffcc00Level 1|r],(|cffffcc00R|r) Shadow Dance - [|cffffcc00Level 2|r],(|cffffcc00R|r) Shadow Dance - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Shadow Dance - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0ec]
                  Tip=(|cffffcc00Q|r) Bloodrage - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Bloodrage - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Bloodrage - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Bloodrage - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Bloodrage - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0Le]
                  Tip=Blood Bath - [|cffffcc00Level 1|r],Blood Bath - [|cffffcc00Level 2|r],Blood Bath - [|cffffcc00Level 3|r],Blood Bath - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Blood Bath - [|cffffcc00Level %d|r]
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0i8]
                  Tip=Strygwyr's Thirst - [|cffffcc00Level 1|r],Strygwyr's Thirst - [|cffffcc00Level 2|r],Strygwyr's Thirst - [|cffffcc00Level 3|r],Strygwyr's Thirst - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Strygwyr's Thirst - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0Lh]
                  Tip=(|cffffcc00R|r) Rupture - [|cffffcc00Level 1|r],(|cffffcc00R|r) Rupture - [|cffffcc00Level 2|r],(|cffffcc00R|r) Rupture - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Rupture - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a030]
                  Tip=(|cffffcc00Q|r) Strafe - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Strafe - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Strafe - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Strafe - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Strafe - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a025]
                  Tip=(|cffffcc00E|r) Wind Walk - [|cffffcc00Level 1|r],(|cffffcc00E|r) Wind Walk - [|cffffcc00Level 2|r],(|cffffcc00E|r) Wind Walk - [|cffffcc00Level 3|r],(|cffffcc00E|r) Wind Walk - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Wind Walk - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a04q]
                  Tip=(|cffffcc00R|r) Death Pact - [|cffffcc00Level 1|r],(|cffffcc00R|r) Death Pact - [|cffffcc00Level 2|r],(|cffffcc00R|r) Death Pact - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Death Pact - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0bh]
                  Tip=(|cffffcc00Q|r) Spawn Spiderlings - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Spawn Spiderlings - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Spawn Spiderlings - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00Q|r) Learn Spawn Spiderlings - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0bg]
                  Tip=(|cffffcc00W|r) Spin Web - [|cffffcc00Level 1|r],(|cffffcc00W|r) Spin Web - [|cffffcc00Level 2|r],(|cffffcc00W|r) Spin Web - [|cffffcc00Level 3|r],(|cffffcc00W|r) Spin Web - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Spin Web - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0bk]
                  Tip=Incapacitating Bite - [|cffffcc00Level 1|r],Incapacitating Bite - [|cffffcc00Level 2|r],Incapacitating Bite - [|cffffcc00Level 3|r],Incapacitating Bite - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Incapacitating Bite - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,2
                  Researchbuttonpos=2,0

                  [a0bm]
                  Tip=Incapacitating Bite
                  Buttonpos=2,0

                  [a0bl]
                  Tip=Incapacitating Bite
                  Buttonpos=2,0

                  [a0bn]
                  Tip=Incapacitating Bite
                  Buttonpos=2,0

                  [a0bo]
                  Tip=Incapacitating Bite
                  Buttonpos=2,0

                  [a0wq]
                  Tip=(|cffffcc00R|r) Insatiable Hunger - [|cffffcc00Level 1|r],(|cffffcc00R|r) Insatiable Hunger - [|cffffcc00Level 2|r],(|cffffcc00R|r) Insatiable Hunger - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Insatiable Hunger - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0bj]
                  Tip=Poison Sting
                  Buttonpos=0,0

                  [a002]
                  Tip=(|cffffcc00W|r) Spawn Spiderlite
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=W
                  Buttonpos=1,0
                  Unbuttonpos=1,0

                  [a0x7]
                  Tip=(|cffffcc00Q|r) Impale - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Impale - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Impale - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Impale - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Impale - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a1h5]
                  Tip=(|cffffcc00W|r) Mana Burn - [|cffffcc00Level 1|r],(|cffffcc00W|r) Mana Burn - [|cffffcc00Level 2|r],(|cffffcc00W|r) Mana Burn - [|cffffcc00Level 3|r],(|cffffcc00W|r) Mana Burn - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Mana Burn - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [A2KO]
                  Tip=(|cffffcc00E|r) Spiked Carapace - [|cffffcc00Level 1|r],(|cffffcc00E|r) Spiked Carapace - [|cffffcc00Level 2|r],(|cffffcc00E|r) Spiked Carapace - [|cffffcc00Level 3|r],(|cffffcc00E|r) Spiked Carapace - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Spiked Carapace - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a09u]
                  Tip=(|cffffcc00R|r) Vendetta - [|cffffcc00Level 1|r],(|cffffcc00R|r) Vendetta - [|cffffcc00Level 2|r],(|cffffcc00R|r) Vendetta - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Vendetta - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1qw]
                  Tip=(|cffffcc00Q|r) The Swarm - [|cffffcc00Level 1|r],(|cffffcc00Q|r) The Swarm - [|cffffcc00Level 2|r],(|cffffcc00Q|r) The Swarm - [|cffffcc00Level 3|r],(|cffffcc00Q|r) The Swarm - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn The Swarm - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0ca]
                  Tip=(|cffffcc00W|r) Shukuchi - [|cffffcc00Level 1|r],(|cffffcc00W|r) Shukuchi - [|cffffcc00Level 2|r],(|cffffcc00W|r) Shukuchi - [|cffffcc00Level 3|r],(|cffffcc00W|r) Shukuchi - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Shukuchi - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0cg]
                  Tip=Geminate Attack - [|cffffcc00Level 1|r],Geminate Attack - [|cffffcc00Level 2|r],Geminate Attack - [|cffffcc00Level 3|r],Geminate Attack - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Geminate Attack - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,2
                  Researchbuttonpos=2,0

                  [a0cn]
                  Tip=Geminate Attack
                  Buttonpos=2,0

                  [a0cr]
                  Tip=Geminate Attack
                  Buttonpos=2,0

                  [a0cs]
                  Tip=Geminate Attack
                  Buttonpos=2,0

                  [a0cm]
                  Tip=Geminate Attack
                  Buttonpos=2,0

                  [a0ct]
                  Tip=(|cffffcc00R|r) Time Lapse - [|cffffcc00Level 1|r],(|cffffcc00R|r) Time Lapse - [|cffffcc00Level 2|r],(|cffffcc00R|r) Time Lapse - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Time Lapse - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1hh]
                  Tip=(|cffffcc00W|r) Infestation
                  Hotkey=W
                  Buttonpos=1,0

                  [a1gc]
                  Tip=(|cffffcc00Q|r) Burrow
                  UnTip=(|cffffcc00Q|r) Unburrow
                  Hotkey=Q
                  Unhotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [a0ym]
                  Tip=(|cffffcc00Q|r) Stifling Dagger - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Stifling Dagger - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Stifling Dagger - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Stifling Dagger - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Stifling Dagger - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0pL]
                  Tip=(|cffffcc00W|r) Blink Strike - [|cffffcc00Level 1|r],(|cffffcc00W|r) Blink Strike - [|cffffcc00Level 2|r],(|cffffcc00W|r) Blink Strike - [|cffffcc00Level 3|r],(|cffffcc00W|r) Blink Strike - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Blink Strike - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a03p]
                  Tip=Blur - [|cffffcc00Level 1|r],Blur - [|cffffcc00Level 2|r],Blur - [|cffffcc00Level 3|r],Blur - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Blur - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a03q]
                  Tip=Coup de GraÃƒ§e - [|cffffcc00Level 1|r],Coup de GraÃƒ§e - [|cffffcc00Level 2|r],Coup de GraÃƒ§e - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Coup de GraÃƒ§e - [|cffffcc00Level %d|r]
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0ey]
                  Tip=(|cffffcc00Q|r) Shadowraze - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Shadowraze - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Shadowraze - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Shadowraze - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Shadowraze - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0fh]
                  Tip=(|cffffcc00W|r) Shadowraze - [|cffffcc00Level 1|r],(|cffffcc00W|r) Shadowraze - [|cffffcc00Level 2|r],(|cffffcc00W|r) Shadowraze - [|cffffcc00Level 3|r],(|cffffcc00W|r) Shadowraze - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00|r)
                  Hotkey=W
                  Researchhotkey=
                  Buttonpos=1,0
                  Researchbuttonpos=,

                  [a0f0]
                  Tip=(|cffffcc00E|r) Shadowraze - [|cffffcc00Level 1|r],(|cffffcc00E|r) Shadowraze - [|cffffcc00Level 2|r],(|cffffcc00E|r) Shadowraze - [|cffffcc00Level 3|r],(|cffffcc00E|r) Shadowraze - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00|r)
                  Hotkey=E
                  Researchhotkey=
                  Buttonpos=2,0
                  Researchbuttonpos=,

                  [a0br]
                  Tip=Necromastery - [|cffffcc00Level 1|r],Necromastery - [|cffffcc00Level 2|r],Necromastery - [|cffffcc00Level 3|r],Necromastery - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Necromastery - [|cffffcc00Level %d|r]
                  Researchhotkey=W
                  Buttonpos=1,2
                  Researchbuttonpos=1,0

                  [a0fu]
                  Tip=Presence of the Dark Lord - [|cffffcc00Level 1|r],Presence of the Dark Lord - [|cffffcc00Level 2|r],Presence of the Dark Lord - [|cffffcc00Level 3|r],Presence of the Dark Lord - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Presence of the Dark Lord - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,1
                  Researchbuttonpos=2,0

                  [A29J]
                  Tip=(|cffffcc00R|r) Requiem of Souls - [|cffffcc00Level 1|r],(|cffffcc00R|r) Requiem of Souls - [|cffffcc00Level 2|r],(|cffffcc00R|r) Requiem of Souls - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Requiem of Souls - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0h4]
                  Tip=(|cffffcc00W|r) Conjure Image - [|cffffcc00Level 1|r],(|cffffcc00W|r) Conjure Image - [|cffffcc00Level 2|r],(|cffffcc00W|r) Conjure Image - [|cffffcc00Level 3|r],(|cffffcc00W|r) Conjure Image - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Conjure Image - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [A2KZ]
                  Tip=(|cffffcc00Q|r) Reflection - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Reflection - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Reflection - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Reflection - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Reflection - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a1ri]
                  Tip=(|cffffcc00E|r) Metamorphosis - [|cffffcc00Level 1|r],(|cffffcc00E|r) Metamorphosis - [|cffffcc00Level 2|r],(|cffffcc00E|r) Metamorphosis - [|cffffcc00Level 3|r],(|cffffcc00E|r) Metamorphosis - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Metamorphosis - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a07q]
                  Tip=(|cffffcc00R|r) Sunder - [|cffffcc00Level 1|r],(|cffffcc00R|r) Sunder - [|cffffcc00Level 2|r],(|cffffcc00R|r) Sunder - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Sunder - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0hw]
                  Tip=(|cffffcc00Q|r) Spectral Dagger - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Spectral Dagger - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Spectral Dagger - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Spectral Dagger - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Spectral Dagger - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0fx]
                  Tip=Desolate - [|cffffcc00Level 1|r],Desolate - [|cffffcc00Level 2|r],Desolate - [|cffffcc00Level 3|r],Desolate - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Desolate - [|cffffcc00Level %d|r]
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0na]
                  Tip=Dispersion - [|cffffcc00Level 1|r],Dispersion - [|cffffcc00Level 2|r],Dispersion - [|cffffcc00Level 3|r],Dispersion - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Dispersion - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a0h9]
                  Tip=(|cffffcc00R|r) Haunt - [|cffffcc00Level 1|r],(|cffffcc00R|r) Haunt - [|cffffcc00Level 2|r],(|cffffcc00R|r) Haunt - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Haunt - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0ha]
                  Tip=(|cffffcc00D|r) Reality - [|cffffcc00Level 1|r],(|cffffcc00D|r) Reality - [|cffffcc00Level 2|r],(|cffffcc00D|r) Reality - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00X|r) Learn Reality - [|cffffcc00Level %d|r]
                  Hotkey=D
                  Researchhotkey=X
                  Buttonpos=2,1
                  Researchbuttonpos=1,2

                  [A173]
                  Tip=(|cffffcc00Q|r) Venomous Gale - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Venomous Gale - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Venomous Gale - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Venomous Gale - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Venomous Gale - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [a0my]
                  Tip=Poison Sting - [|cffffcc00Level 1|r],Poison Sting - [|cffffcc00Level 2|r],Poison Sting - [|cffffcc00Level 3|r],Poison Sting - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Poison Sting - [|cffffcc00Level %d|r]
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0ms]
                  Tip=(|cffffcc00E|r) Plague Ward - [|cffffcc00Level 1|r],(|cffffcc00E|r) Plague Ward - [|cffffcc00Level 2|r],(|cffffcc00E|r) Plague Ward - [|cffffcc00Level 3|r],(|cffffcc00E|r) Plague Ward - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Plague Ward - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a013]
                  Tip=(|cffffcc00R|r) Poison Nova - [|cffffcc00Level 1|r],(|cffffcc00R|r) Poison Nova - [|cffffcc00Level 2|r],(|cffffcc00R|r) Poison Nova - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Poison Nova - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a0a6]
                  Tip=(|cffffcc00R|r) Poison Nova (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Poison Nova (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Poison Nova (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Poison Nova (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a09v]
                  Tip=(|cffffcc00Q|r) Poison Attack - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Poison Attack - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Poison Attack - [|cffffcc00Level 3|r]
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Researchtip=(|cffffcc00Q|r) Learn Poison Attack - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0
                  Researchbuttonpos=0,0

                  [a1a3]
                  Tip=Nethertoxin - [|cffffcc00Level 1|r],Nethertoxin - [|cffffcc00Level 2|r],Nethertoxin - [|cffffcc00Level 3|r],Nethertoxin - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Nethertoxin - [|cffffcc00Level %d|r]
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [a0mm]
                  Tip=Corrosive Skin - [|cffffcc00Level 1|r],Corrosive Skin - [|cffffcc00Level 2|r],Corrosive Skin - [|cffffcc00Level 3|r],Corrosive Skin - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Corrosive Skin - [|cffffcc00Level %d|r]
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [a080]
                  Tip=(|cffffcc00R|r) Viper Strike - [|cffffcc00Level 1|r],(|cffffcc00R|r) Viper Strike - [|cffffcc00Level 2|r],(|cffffcc00R|r) Viper Strike - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Viper Strike - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [a1UZ]
                  Tip=(|cffffcc00R|r) Viper Strike (Aghanim's Scepter) - [|cffffcc00Level 1|r],(|cffffcc00R|r) Viper Strike (Aghanim's Scepter) - [|cffffcc00Level 2|r],(|cffffcc00R|r) Viper Strike (Aghanim's Scepter) - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Viper Strike (Aghanim's Scepter) - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [A2M1]
                  Tip=(|cffffcc00Q|r) Flux - [|cffffcc00Level 1|r],(|cffffcc00Q|r) Flux - [|cffffcc00Level 2|r],(|cffffcc00Q|r) Flux - [|cffffcc00Level 3|r],(|cffffcc00Q|r) Flux - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00Q|r) Learn Flux - [|cffffcc00Level %d|r]
                  Hotkey=Q
                  Researchhotkey=Q
                  Buttonpos=0,0
                  Researchbuttonpos=0,0

                  [A2LM]
                  Tip=(|cffffcc00W|r) Magnetic Field - [|cffffcc00Level 1|r],(|cffffcc00W|r) Magnetic Field - [|cffffcc00Level 2|r],(|cffffcc00W|r) Magnetic Field - [|cffffcc00Level 3|r],(|cffffcc00W|r) Magnetic Field - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00W|r) Learn Magnetic Field - [|cffffcc00Level %d|r]
                  Hotkey=W
                  Researchhotkey=W
                  Buttonpos=1,0
                  Researchbuttonpos=1,0

                  [A2LL]
                  Tip=(|cffffcc00E|r) Spark Wraith - [|cffffcc00Level 1|r],(|cffffcc00E|r) Spark Wraith - [|cffffcc00Level 2|r],(|cffffcc00E|r) Spark Wraith - [|cffffcc00Level 3|r],(|cffffcc00E|r) Spark Wraith - [|cffffcc00Level 4|r]
                  Researchtip=(|cffffcc00E|r) Learn Spark Wraith - [|cffffcc00Level %d|r]
                  Hotkey=E
                  Researchhotkey=E
                  Buttonpos=2,0
                  Researchbuttonpos=2,0

                  [A2M0]
                  Tip=(|cffffcc00R|r) Tempest Double - [|cffffcc00Level 1|r],(|cffffcc00R|r) Tempest Double - [|cffffcc00Level 2|r],(|cffffcc00R|r) Tempest Double - [|cffffcc00Level 3|r]
                  Researchtip=(|cffffcc00R|r) Learn Tempest Double - [|cffffcc00Level %d|r]
                  Hotkey=R
                  Researchhotkey=R
                  Buttonpos=3,0
                  Researchbuttonpos=3,0

                  [aamk]
                  Tip=Attribute Bonus
                  Researchtip=(|cffffcc00U|r) Learn Attribute Bonus - [|cffffcc00Level %d|r]
                  Researchhotkey=U
                  Buttonpos=1,2
                  Researchbuttonpos=1,2

                  [a0nr]
                  Tip=Attribute Bonus
                  Researchtip=(|cffffcc00X|r) Learn Attribute Bonus - [|cffffcc00Level %d|r]
                  Researchhotkey=X
                  Buttonpos=1,1
                  Researchbuttonpos=1,2

                  [A0WZ]
                  Tip=(|cffffcc00Q|r) Thunder Clap
                  Hotkey=Q
                  Buttonpos=0,0

                  [acf2]
                  Tip=(|cffffcc00Q|r) Frost Armor
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [a0gv]
                  Tip=(|cffffcc00Q|r) Mana Burn
                  Hotkey=Q
                  Buttonpos=0,0

                  [a0jv]
                  Tip=(|cffffcc00Q|r) Mana Burn
                  Hotkey=Q
                  Buttonpos=0,0

                  [a0jw]
                  Tip=(|cffffcc00Q|r) Mana Burn
                  Hotkey=Q
                  Buttonpos=0,0

                  [a0gy]
                  Tip=Necronomicon Endurance Aura
                  Buttonpos=1,0

                  [a0gb]
                  Tip=Necronomicon Endurance Aura
                  Buttonpos=1,0

                  [a0hn]
                  Tip=Necronomicon Endurance Aura
                  Buttonpos=1,0

                  [a0h3]
                  Tip=Spell Immunity
                  Buttonpos=2,0

                  [a0gw]
                  Tip=Mana Break
                  Buttonpos=0,0

                  [a0m2]
                  Tip=Mana Break
                  Buttonpos=0,0

                  [a0m4]
                  Tip=Mana Break
                  Buttonpos=0,2

                  [a0gu]
                  Tip=Last Will
                  Buttonpos=1,0

                  [a0gx]
                  Tip=Last Will
                  Buttonpos=1,0

                  [a0gz]
                  Tip=Last Will
                  Buttonpos=3,2

                  [a0g1]
                  Tip=Command Aura
                  Buttonpos=1,0

                  [a0xd]
                  Tip=(|cffffcc00Q|r) Frost Attack
                  UnTip=|cffc3dbffRight-click to activate auto-casting.|r
                  Hotkey=Q
                  Buttonpos=0,0
                  Unbuttonpos=0,0

                  [A1as]
                  Tip=(|cffffcc00Y|r) Return Home
                  Hotkey=Y
                  Buttonpos=0,2

                  [A0OT]
                  Tip=(|cffffcc00S|r) Change Courier Type
                  Hotkey=S
                  Buttonpos=1,1

                  [A138]
                  Tip=(|cffffcc00X|r) Drop Items
                  Hotkey=X
                  Buttonpos=1,2

                  [H0DE]
                  Tip=(|cffffcc00C|r) Resume Delivery
                  Hotkey=C
                  Buttonpos=2,2

                  [h085]
                  Tip=(|cffffcc00R|r) Transfer Items
                  Hotkey=R
                  Buttonpos=3,0

                  [h0bv]
                  Tip=(|cffffcc00V|r) Collect Your Items
                  Hotkey=V
                  Buttonpos=3,2

                  [a0jz]
                  Tip=(|cffffcc00D|r) Burst
                  Hotkey=D
                  Buttonpos=2,1

                  [h06n]
                  Tip=(|cffffcc00Q|r) Select Hero
                  Hotkey=Q
                  Buttonpos=0,0


                  //////////////////////////////////////////////////////////////////////////////
                  // I believe I have found 3 small errors, I have tested multiple different Customkeys.txt files
                  // Morph Into Destroyer, Train Berserker, and Train Engine Barrage do NOT work with any setup
                  // Seems like a hardcoded problem within the game itself, nothing Customkeys.txt can fix
                  ///////////////////////////////////////////////////////////////////
                '';
              };
            };
          };
        };
      };
    };
  };
}
