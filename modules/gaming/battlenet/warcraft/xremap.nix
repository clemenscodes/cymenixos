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
            T: F8

        - name: Better Control Groups
          remap:
            KEY_1:
              held:
                - LeftCtrl
                - KEY_1
              alone:
                - KEY_1
                - KEY_U
              alone_timeout_millis: 1500
            KEY_2:
              held:
                - LeftCtrl
                - KEY_2
              alone:
                - KEY_2
                - KEY_I
              alone_timeout_millis: 1500
            KEY_3:
              held:
                - LeftCtrl
                - KEY_3
              alone:
                - KEY_3
                - KEY_O
              alone_timeout_millis: 1500
            KEY_4:
              held:
                - LeftCtrl
                - KEY_4
              alone:
                - KEY_4
                - KEY_P
              alone_timeout_millis: 1500
            KEY_5:
              held:
                - LeftCtrl
                - KEY_5
              alone:
                - KEY_5
                - KEY_H
              alone_timeout_millis: 1500
            KEY_6:
              held:
                - LeftCtrl
                - KEY_6
              alone:
                - KEY_6
                - KEY_J
              alone_timeout_millis: 1500
            KEY_7:
              held:
                - LeftCtrl
                - KEY_7
              alone:
                - KEY_7
                - KEY_K
              alone_timeout_millis: 1500
            KEY_8:
              held:
                - LeftCtrl
                - KEY_8
              alone:
                - KEY_8
                - KEY_L
              alone_timeout_millis: 1500
            KEY_9:
              held:
                - LeftCtrl
                - KEY_9
              alone:
                - KEY_9
                - KEY_N
              alone_timeout_millis: 1500
            KEY_0:
              held:
                - LeftCtrl
                - KEY_0
              alone:
                - KEY_0
                - KEY_M
              alone_timeout_millis: 1500

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
