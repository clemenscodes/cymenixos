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
      packages = with pkgs; [television];
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
          "basher"
          "toml"
          "json5"
          "git-firefly"
          "github-actions"
          "angular"
          "crates-lsp"
          "vscode-icons"
          "dockerfile"
          "csv"
          "env"
          "log"
          "lua"
          "latex"
          "html"
          "helm"
          "docker-compose"
          "nginx"
          "markdown-oxide"
          "terraform"
          "prisma"
          "sql"
          "make"
          "scss"
          "ini"
          "neocmake"
          "color-highlight"
        ];
        extraPackages = with pkgs; [nil nixd codex-acp television];
        mutableUserKeymaps = true;
        mutableUserSettings = true;
        mutableUserTasks = true;
        mutableUserDebug = true;
        userDebug = [];
        userTasks = [
          {
            "label" = "lazygit";
            "command" = "lazygit";
            "use_new_terminal" = false;
            "allow_concurrent_runs" = false;
            "hide" = "always";
            "reveal" = "always";
            "cwd" = "$ZED_DIRNAME";
            "shell" = {
              "with_arguments" = {
                "program" = "sh";
                "args" = ["--noediting" "--norc" "--noprofile"];
              };
            };
          }
          {
            "label" = "file_finder";
            "command" = "${pkgs.television}/bin/tv files";
            "hide" = "always";
            "reveal" = "always";
            "use_new_terminal" = true;
            "allow_concurrent_runs" = true;
            "cwd" = "$ZED_WORKTREE_ROOT";
            "shell" = {
              "with_arguments" = {
                "program" = "sh";
                "args" = ["--noediting" "--norc" "--noprofile"];
              };
            };
          }
          {
            "label" = "fulltext_search";
            "command" = "${pkgs.television}/bin/tv text";
            "cwd" = "$ZED_WORKTREE_ROOT";
            "hide" = "always";
            "reveal" = "always";
            "use_new_terminal" = true;
            "allow_concurrent_runs" = true;
            "shell" = {
              "with_arguments" = {
                "program" = "sh";
                "args" = ["--noediting" "--norc" "--noprofile"];
              };
            };
          }
          {
            "label" = "find_selected_text";
            "command" = "${pkgs.television}/bin/tv text -i \"$ZED_SELECTED_TEXT\"";
            "cwd" = "$ZED_WORKTREE_ROOT";
            "hide" = "always";
            "reveal" = "always";
            "use_new_terminal" = true;
            "allow_concurrent_runs" = true;
            "shell" = {
              "with_arguments" = {
                "program" = "sh";
                "args" = ["--noediting" "--norc" "--noprofile"];
              };
            };
          }
        ];
        userKeymaps = [
          {
            context = "(VimControl && !menu)";
            bindings = {
              space = null;
            };
          }
          {
            "context" = "Dock || Terminal || Editor || ProjectPanel || AssistantPanel || CollabPanel || OutlinePanel || ChatPanel || VimControl || EmptyPane || SharedScreen || MarkdownPreview || KeyContextView || Diagnostics";
            "bindings" = {
              "ctrl-h" = ["workspace::ActivatePaneInDirection" "Left"];
              "ctrl-l" = ["workspace::ActivatePaneInDirection" "Right"];
              "ctrl-k" = ["workspace::ActivatePaneInDirection" "Up"];
              "ctrl-j" = ["workspace::ActivatePaneInDirection" "Down"];
            };
          }
          {
            "context" = "ProjectPanel || EmptyPane || (Editor && VimControl && !VimWaiting && !menu)";
            "bindings" = {
              "space space" = "terminal_panel::Toggle";
              "space e" = "workspace::ToggleLeftDock";
              "space i" = "workspace::Save";
              "space f f" = [
                "task::Spawn"
                {
                  "task_name" = "file_finder";
                  "reveal_target" = "center";
                }
              ];
              "space f g" = [
                "task::Spawn"
                {
                  "task_name" = "fulltext_search";
                  "reveal_target" = "center";
                }
              ];
              "space f s" = [
                "task::Spawn"
                {
                  "task_name" = "find_selected_text";
                  "reveal_target" = "center";
                }
              ];
              "space g g" = ["task::Spawn" {"task_name" = "lazygit";}];
              "ctrl-o" = "pane::CloseInactiveItems";
              "space c a" = "editor::ToggleCodeActions";
              "g r" = "editor::FindAllReferences";
            };
          }
          {
            "context" = "Editor && showing_completions";
            "bindings" = {
              "tab" = "editor::ContextMenuNext";
              "shift-tab" = "editor::ContextMenuPrev";
            };
          }
          {
            "context" = "Editor && vim_mode == normal && (vim_operator == none || vim_operator == n) && !VimWaiting";
            "bindings" = {
              "space q" = "pane::CloseActiveItem";
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
              "shift-d" = ["project_panel::Trash" {"skip_prompt" = true;}];
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
              "ctrl-l" = ["terminal::SendKeystroke" "ctrl-l"];
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
          agent_ui_font_size = 20;
          vim_mode = true;
          scroll_beyond_last_line = "off";
          vertical_scroll_margin = 0;
          double_click_in_multibuffer = "open";
          close_on_file_delete = true;
          use_smartcase_search = true;
          autosave = "off";
          format_on_save = "on";
          ui_font_family = "Lilex Nerd Font";
          buffer_font_family = "Lilex Nerd Font";
          load_direnv = "shell_hook";
          hour_format = "hour24";
          base_keymap = "VSCode";

          cursor_blink = false;
          rounded_selection = false;
          colorize_brackets = true;
          document_symbols = "on";
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
            delay_ms = 300;
          };

          vim = {
            use_smartcase_find = true;
            highlight_on_yank_duration = 500;
          };

          git = {
            inline_blame = {
              delay_ms = 200;
              show_commit_summary = true;
            };
          };

          indent_guides = {
            coloring = "indent_aware";
          };

          seed_search_query_from_cursor = "selection";

          diagnostics = {
            inline = {
              enabled = true;
            };
          };

          excerpt_context_lines = 3;
          expand_excerpt_lines = 10;

          title_bar = {
            show_menus = true;
            show_branch_icon = true;
            show_sign_in = false;
          };

          tab_bar = {
            show_nav_history_buttons = false;
            show_tab_bar_buttons = false;
          };

          tabs = {
            show_diagnostics = "errors";
            git_status = true;
            file_icons = true;

            activate_on_close = "neighbour";
          };

          project_panel = {
            default_width = 300;
            auto_fold_dirs = false;
            auto_reveal_entries = false;
            entry_spacing = "standard";
          };

          outline_panel = {
            dock = "right";
          };

          git_panel = {
            tree_view = true;
            sort_by_path = true;
            default_width = 300;
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
            Terraform = {
              format_on_save = "on";
              formatter = {
                external = {
                  command = "tofu";
                  arguments = ["fmt" "-"];
                };
              };
            };
          };

          lsp = {
            rust-analyzer = {
              binary = {
                path_lookup = true;
              };
              initialization_options = {
                check = {
                  command = "clippy";
                };
                cargo = {
                  allFeatures = true;
                  loadOutDirsFromCheck = true;
                  buildScripts = {
                    enable = true;
                  };
                };
                procMacro = {
                  enable = true;
                  ignored = {
                    async-trait = ["async_trait"];
                    napi-derive = ["napi"];
                    async-recursion = ["async_recursion"];
                  };
                };
                rust = {
                  analyzerTargetDir = true;
                };
                inlayHints = {
                  maxLength = null;
                  lifetimeElisionHints = {
                    enable = "skip_trivial";
                    useParameterNames = true;
                  };
                  closureReturnTypeHints = {
                    enable = "always";
                  };
                };
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
