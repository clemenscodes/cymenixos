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
  configFile = pkgs.writeTextFile {
    name = "xremap-warcraft.yml";
    text = ''
      modmap:
        - name: Better Caps
          remap:
            CapsLock:
              held: SUPER_L
              alone: ESC
              alone_timeout_millis: 500

        - name: Swap Space & Ctrl
          remap:
            LeftCtrl: Space
            Space: LeftCtrl

        - name: Idle workers
          remap:
            B: F8

      keymap:
        - name: Better Control Groups
          remap:
            SUPER-KEY_1: KEY_6
            SUPER-KEY_2: KEY_7
            SUPER-KEY_3: KEY_8
            SUPER-KEY_4: KEY_9
            SUPER-KEY_5: KEY_0
            SHIFT-KEY_1: KEY_F1
            SHIFT-KEY_2: KEY_F2
            SHIFT-KEY_3: KEY_F3
            SHIFT-KEY_4: KEY_F4
            SHIFT-KEY_5: KEY_F5
            SHIFT-KEY_6: KEY_F6
            BTN_EXTRA-KEY_1: LeftCtrl-KEY_1
            BTN_EXTRA-KEY_2: LeftCtrl-KEY_2
            BTN_EXTRA-KEY_3: LeftCtrl-KEY_3
            BTN_EXTRA-KEY_4: LeftCtrl-KEY_4
            BTN_EXTRA-KEY_5: LeftCtrl-KEY_5
            BTN_SIDE-KEY_1: LeftCtrl-KEY_6
            BTN_SIDE-KEY_2: LeftCtrl-KEY_7
            BTN_SIDE-KEY_3: LeftCtrl-KEY_8
            BTN_SIDE-KEY_4: LeftCtrl-KEY_9
            BTN_SIDE-KEY_5: LeftCtrl-KEY_0
    '';
  };
  chatConfigFile = pkgs.writeTextFile {
    name = "xremap-warcraft-chat.yml";
    text = ''
      modmap:
        - name: Better Caps
          remap:
            CapsLock:
              held: SUPER_L
              alone: ESC
              alone_timeout_millis: 500
    '';
  };
  start-xremap-warcraft = pkgs.writeShellApplication {
    name = "start-xremap-warcraft";
    text = ''
      XREMAP=/tmp/xremap
      mkdir -p "$XREMAP"
      cat ${chatConfigFile} > "$XREMAP/warcraft-chat.yaml"
      cat ${configFile} > "$XREMAP/warcraft-config.yaml"
      cat ${configFile} > "$XREMAP/warcraft.yaml"
      ${lib.getExe config.services.xremap.package} --watch=config "$XREMAP/warcraft.yaml"
    '';
  };
in {
  config = lib.mkIf (cfg.enable && cfg.warcraft.enable) {
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
                ExecStart = "${lib.getExe start-xremap-warcraft}";
              }
              (lib.optionalAttrs config.services.xremap.debug {Environment = ["RUST_LOG=debug"];})
            ];
          };
        };
      };
    };
  };
}
