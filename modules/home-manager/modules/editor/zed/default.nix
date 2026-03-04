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
          autosave = "on_focus_change";
          buffer_font_family = "Lilex Nerd Font";
          load_direnv = "shell_hook";
          hour_format = "hour24";
          base_keymap = "VSCode";

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

          icon_theme = "Catppuccin Macchiato";
          theme = {
            mode = "system";
            dark = "Catppuccin Macchiato (blue)";
            light = "Catppuccin Macchiato (blue)";
          };
        };
      };
    };
  };
}
