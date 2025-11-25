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
  imports = [inputs.anyrun.homeManagerModules.anyrun];
  disabledModules = ["${modulesPath}/programs/anyrun.nix"];
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
          extraLines = ''
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
        extraCss =
          /*
          css
          */
          ''
            * {
              all: unset;
              font-size: 1.2rem;
            }

            #window,
            #match,
            #entry,
            #plugin,
            #main {
              background: transparent;
            }

            #match.activatable {
              border-radius: 8px;
              margin: 4px 0;
              padding: 4px;
            }
            #match.activatable:first-child {
              margin-top: 12px;
            }
            #match.activatable:last-child {
              margin-bottom: 0;
            }

            #match:hover {
              background: rgba(255, 255, 255, 0.05);
            }
            #match:selected {
              background: rgba(255, 255, 255, 0.1);
            }

            #entry {
              background: rgba(255, 255, 255, 0.05);
              border: 1px solid rgba(255, 255, 255, 0.1);
              border-radius: 8px;
              padding: 4px 8px;
            }

            box#main {
              background: rgba(0, 0, 0, 0.5);
              box-shadow:
                inset 0 0 0 1px rgba(255, 255, 255, 0.1),
                0 30px 30px 15px rgba(0, 0, 0, 0.5);
              border-radius: 20px;
              padding: 12px;
            }
          '';
      };
    };
  };
}
