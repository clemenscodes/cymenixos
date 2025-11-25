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
  anyrun = inputs.anyrun.packages.${pkgs.stdenv.hostPlatform.system};
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
    home = {
      packages = [anyrun.default];
    };
    programs = {
      anyrun = {
        enable = true;
        package = anyrun.default;
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
          plugins = with anyrun; [
            applications
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
            :root {
              --bg-color: #313244;
              --fg-color: #cdd6f4;
              --primary-color: #89b4fa;
              --secondary-color: #cba6f7;
              --border-color: var(--primary-color);
              --selected-bg-color: var(--primary-color);
              --selected-fg-color: var(--bg-color);
            }

            * {
              all: unset;
              font-family: "Iosevka Nerd Font", monospace;
            }

            window {
              background: transparent;
            }

            box.main {
              border-radius: 16px;
              background-color: var(--bg-color);
              border: 0.5px solid var(--fg-color);
              padding: 12px;
            }

            text {
              font-size: 1.3rem;
              background: transparent;
              border: 1px solid var(--border-color);
              border-radius: 16px;
              margin-bottom: 12px;
              padding: 5px;
              min-height: 44px;
              caret-color: var(--primary-color);
            }

            .matches {
              background-color: transparent;
            }

            .match {
              font-size: 1.1rem;
              padding: 5px;
              border-radius: 6px;
            }

            .match * {
              margin: 0;
              padding: 0;
              line-height: 1;
            }

            .match:selected,
            .match:hover {
              background-color: var(--selected-bg-color);
              color: var(--selected-fg-color);
            }

            .match:selected label.plugin.info,
            .match:hover label.plugin.info {
              color: var(--selected-fg-color);
            }

            .match:selected label.match.description,
            .match:hover label.match.description {
              color: var(--selected-fg-color);
            }

            label.plugin.info {
              color: var(--fg-color);
              font-size: 1rem;
              min-width: 160px;
              text-align: left;
            }

            label.match.description {
              font-size: 0rem;
              color: var(--fg-color);
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
