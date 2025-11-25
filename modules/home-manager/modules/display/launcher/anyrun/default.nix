{
  inputs,
  pkgs,
  lib,
  ...
}: {
  osConfig,
  config,
  modulesPath,
  ...
}: let
  cfg = config.modules.display.launcher;
in {
  options = {
    modules = {
      display = {
        launcher = {
          anyrun = {
            enable = lib.mkEnableOption "Enable anyrun" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.anyrun.enable) {
    disabledModules = ["${modulesPath}/programs/anyrun.nix"];
    home = {
      packages = [pkgs.anyrun];
    };
    programs = {
      anyrun = {
        enable = true;
        config = {
          layer = "overlay";
          x = {
            fraction = 0.5;
          };
          y = {
            fraction = 0.3;
          };
          width = {
            fraction = 0.3;
          };
          hideIcons = false;
          ignoreExclusiveZones = false;
          hidePluginInfo = false;
          closeOnClick = false;
          showResultsImmediately = false;
          maxEntries = null;
          plugins = [
            "${pkgs.anyrun}/lib/libapplications.so"
          ];
          extraLines = {
            "keybinds.ron" = {
              text = ''
                keybinds: [
                  Keybind(
                    key: "Return",
                    action: Select,
                  ),
                  Keybind(
                    key: "Up",
                    action: Up,
                  ),
                  Keybind(
                    key: "Down",
                    action: Down,
                  ),
                  Keybind(
                    key: "ISO_Left_Tab",
                    action: Up,
                    shift: true,
                  ),
                  Keybind(
                    key: "Tab",
                    action: Down,
                  ),
                  Keybind(
                    key: "Escape",
                    action: Close,
                  ),
                ],
              '';
            };
          };
        };
        extraCss =
          /*
          css
          */
          ''
            @define-color accent #5599d2;
            @define-color bg-color #161616;
            @define-color fg-color #eeeeee;
            @define-color desc-color #cccccc;

            window {
              background: transparent;
            }

            box.main {
              padding: 2px;
              margin: 2px;
              border-radius: 10px;
              border: 2px solid @accent;
              background-color: @bg-color;
              box-shadow: 0 0 5px black;
            }

            text {
              min-height: 30px;
              padding: 10px;
              border-radius: 5px;
              color: @fg-color;
            }

            .matches {
              background-color: rgba(0, 0, 0, 0);
              border-radius: 10px;
              padding: 10px;
              margin: 10px;
            }

            box.plugin:first-child {
              margin-top: 5px;
            }

            box.plugin.info {
              min-width: 200px;
            }

            list.plugin {
              background-color: rgba(0, 0, 0, 0);
            }

            label.match {
              color: @fg-color;
            }

            label.match.description {
              font-size: 10px;
              color: @desc-color;
            }

            label.plugin.info {
              font-size: 14px;
              color: @fg-color;
            }

            #match {
              background: transparent;
            }

            #match:selected {
              border-left: 4px solid @accent;
              background: transparent;
              animation: fade 0.1s linear;
            }

            @keyframes fade {
              0% {
                opacity: 0;
              }

              100% {
                opacity: 1;
              }
            }
          '';
      };
    };
  };
}
