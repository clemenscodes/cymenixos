{
  inputs,
  pkgs,
  lib,
  ...
}: {
  config,
  osConfig,
  ...
}: let
  cfg = config.modules.editor;
  inherit (osConfig.modules.boot.impermanence) persistPath;
  inherit (osConfig.modules.users) user;
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
    home = {
      persistence = lib.mkIf (osConfig.modules.boot.enable) {
        "${persistPath}" = {
          directories = [".local/share/zed" ".config/zed"];
        };
      };
    };
    programs = {
      zed-editor = {
        inherit (cfg.zed) enable;
        package = inputs.zed.packages.${pkgs.system}.default;
        extensions = [
          "nix"
          "toml"
          "json5"
          "git-firefly"
          "angular"
          "crates-lsp"
          "vscode-icons"
          "dockerfile"
          "sql"
          "make"
          "scss"
          "biome"
          "ini"
          "neocmake"
          "color-highlight"
        ];
        extraPackages = with pkgs; [nil nixd codex-acp];
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
              "space space" = "terminal_panel::Toggle";
              "space e" = "workspace::ToggleLeftDock";
              "space i" = "workspace::Save";
              "space f f" = "file_finder::Toggle";
              "space f g" = "project_search::ToggleFocus";
            };
          }
          {
            "context" = "ProjectPanel && not_editing";
            "bindings" = {
              "space e" = "workspace::ToggleLeftDock";
              "space space" = "terminal_panel::Toggle";
              "l" = "project_panel::Open";
              "r" = "project_panel::Rename";
              "d" = "project_panel::Delete";
              "shift-d" = "project_panel::Trash";
              "a" = "project_panel::NewFile";
              "y" = "project_panel::Copy";
              "p" = "project_panel::Paste";
              "x" = "project_panel::Cut";
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

          auto_update = false;
          ui_font_size = 20;
          buffer_font_size = 20;
          vim_mode = true;
          autosave = "off";
          format_on_save = "on";
          ui_font_family = "Lilex Nerd Font";
          buffer_font_family = "Lilex Nerd Font";
          load_direnv = "shell_hook";
          hour_format = "hour24";
          base_keymap = "VSCode";

          icon_theme = lib.mkForce "VSCode Icons for Zed (Dark)";
          theme = {
            mode = "system";
            dark = lib.mkForce "Catppuccin Macchiato (blue)";
            light = lib.mkForce "Catppuccin Macchiato (blue)";
          };

          session = {
            trust_all_worktrees = true;
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

          which_key = {
            enabled = true;
            delay_ms = 100;
          };

          terminal = {
            font_family = "Lilex Nerd Font";
            copy_on_select = true;
            max_scroll_history_lines = 50000;
          };

          languages = {
            CSS = {
              language_servers = ["tailwindcss-intellisense-css" "!vscode-css-language-server"];
            };
            Rust = {
              language_servers = ["tailwindcss-language-server" "rust-analyzer"];
            };
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
            tailwindcss-language-server = {
              binary = {
                path_lookup = true;
              };
              settings = {
                classFunctions = ["tw" "cva" "cx"];
                includeLanguages = {
                  rust = "html";
                };
                experimental = {
                  classRegex = [
                    "[cls|className]\\s\\:\\=\\s\"([^\"]*)"
                    "class=\"([^\"]*)\""
                    "class: \"(.*)\""
                    "\\.className\\s*[+]?=\\s*['\"]([^'\"]*)['\"]"
                    "\\.setAttributeNS\\(.*,\\s*['\"]class['\"],\\s*['\"]([^'\"]*)['\"]"
                    "\\.setAttribute\\(['\"]class['\"],\\s*['\"]([^'\"]*)['\"]"
                    "\\.classList\\.add\\(['\"]([^'\"]*)['\"]"
                    "\\.classList\\.remove\\(['\"]([^'\"]*)['\"]"
                    "\\.classList\\.toggle\\(['\"]([^'\"]*)['\"]"
                    "\\.classList\\.contains\\(['\"]([^'\"]*)['\"]"
                    "\\.classList\\.replace\\(\\s*['\"]([^'\"]*)['\"]"
                    "\\.classList\\.replace\\([^,)]+,\\s*['\"]([^'\"]*)['\"]"
                  ];
                };
              };
            };
          };

          agent_servers = {
            claude-acp = {
              type = "registry";
              env = {
                CLAUDE_CODE_EXECUTABLE = "claude";
              };
            };
            codex-acp = {
              type = "custom";
              command = "${pkgs.codex-acp}/bin/codex-acp";
              args = [];
              env = {
                CODEX_HOME = "/home/${user}/.config/codex";
              };
            };
          };
        };
      };
    };
  };
}
