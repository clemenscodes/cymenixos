{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.editor;
in {
  options = {
    modules = {
      editor = {
        zed = {
          enable = lib.mkEnableOption "Enable zed" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.zed.enable) {
    programs = {
      zed-editor = {
        inherit (cfg.zed) enable;
        package = inputs.zed.packages.${pkgs.system}.default;
        extensions = ["nix" "toml" "yaml" "json5" "git-firefly" "angular" "rust" "vscode-icons"];
        extraPackages = with pkgs; [nil nixd];
        mutableUserKeymaps = true;
        mutableUserSettings = true;
        userKeymaps = [
          {
            context = "(VimControl && !menu)";
            bindings = {
              space = null;
            };
          }
          {
            "context" = "Editor";
            "bindings" = {
              "ctrl-h" = ["workspace::ActivatePaneInDirection" "Left"];
              "ctrl-l" = ["workspace::ActivatePaneInDirection" "Right"];
              "ctrl-k" = ["workspace::ActivatePaneInDirection" "Up"];
              "ctrl-j" = ["workspace::ActivatePaneInDirection" "Down"];
            };
          }
          {
            "context" = "Editor && vim_mode == normal";
            "bindings" = {
              "space e" = "workspace::ToggleLeftDock";
              "space i" = "workspace::Save";
              "space f f" = "file_finder::Toggle";
            };
          }
          {
            "context" = "ProjectPanel";
            "bindings" = {
              "space e" = "workspace::ToggleLeftDock";
            };
          }
          {
            "context" = "Terminal";
            "bindings" = {
              "ctrl-/" = "workspace::ToggleBottomDock";
            };
          }
          {
            context = "Dock";
            bindings = {
              "ctrl-h" = ["workspace::ActivatePaneInDirection" "Left"];
              "ctrl-l" = ["workspace::ActivatePaneInDirection" "Right"];
              "ctrl-k" = ["workspace::ActivatePaneInDirection" "Up"];
              "ctrl-j" = ["workspace::ActivatePaneInDirection" "Down"];
            };
          }
        ];
        userSettings = {
          telemetry = {
            diagnostics = false;
            metrics = false;
          };
          minimap = {
            show = "never";
          };
          scrollbar = {
            axes = {
              horizontal = false;
              vertical = false;
            };
          };
          auto_update = false;
          ui_font_size = 16;
          buffer_font_size = 16;
          vim_mode = true;
          autosave = "off";
          format_on_save = "on";
          buffer_font_family = "Lilex Nerd Font";
          load_direnv = "shell_hook";
          hour_format = "hour24";
          base_keymap = "VSCode";

          which_key = {
            enabled = true;
            delay_ms = 100;
          };

          terminal = {
            font_family = "Lilex Nerd Font";
            copy_on_select = true;
            max_scroll_history_lines = 50000;
          };

          lsp = {
            rust-analyzer = {
              binary = {
                path_lookup = true;
              };
            };
            nix = {
              binary = {
                path_lookup = true;
              };
            };
          };

          icon_theme = lib.mkForce "VSCode Icons for Zed (Dark)";
          theme = {
            mode = "system";
            dark = lib.mkForce "Catppuccin Macchiato (blue)";
            light = lib.mkForce "Catppuccin Macchiato (blue)";
          };
        };
      };
    };
  };
}
