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
            @define-color bg-color #313244;
            @define-color fg-color #cdd6f4;
            @define-color primary-color #89b4fa;
            @define-color secondary-color #cba6f7;
            @define-color border-color @primary-color;
            @define-color selected-bg-color @primary-color;
            @define-color selected-fg-color @bg-color;

            * {
              all: unset;
              font-family: JetBrainsMono Nerd Font;
            }

            #window {
              background: transparent;
            }

            box#main {
              border-radius: 16px;
              background-color: alpha(@bg-color, 0.6);
              border: 0.5px solid alpha(@fg-color, 0.25);
            }

            entry#entry {
              font-size: 1.25rem;
              background: transparent;
              box-shadow: none;
              border: none;
              border-radius: 16px;
              padding: 16px 24px;
              min-height: 40px;
              caret-color: @primary-color;
            }

            list#main {
              background-color: transparent;
            }

            #plugin {
              background-color: transparent;
              padding-bottom: 4px;
            }

            #match {
              font-size: 1.1rem;
              padding: 2px 4px;
            }

            #match:selected,
            #match:hover {
              background-color: @selected-bg-color;
              color: @selected-fg-color;
            }

            #match:selected label#info,
            #match:hover label#info {
              color: @selected-fg-color;
            }

            #match:selected label#match-desc,
            #match:hover label#match-desc {
              color: alpha(@selected-fg-color, 0.9);
            }

            #match label#info {
              color: transparent;
              color: @fg-color;
            }

            label#match-desc {
              font-size: 1rem;
              color: @fg-color;
            }

            label#plugin {
              font-size: 16px;
            }
          '';
      };
    };
  };
}
