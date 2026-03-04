{
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
        extensions = ["nix" "toml" "yaml" "json5" "git-firefly" "angular" "rust" "vscode-icons"];
        extraPackages = with pkgs; [nil];
        mutableUserKeymaps = true;
        mutableUserSettings = true;
        userSettings = {
          auto_update = false;
          ui_font_size = 16;
          buffer_font_size = 16;
          vim_mode = true;
          load_direnv = "shell_hook";
          hour_format = "hour24";
          base_keymap = "VSCode";

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
