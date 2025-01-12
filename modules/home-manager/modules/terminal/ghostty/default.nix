{lib, ...}: {config, ...}: let
  cfg = config.modules.terminal;
in {
  options = {
    modules = {
      terminal = {
        ghostty = {
          enable = lib.mkEnableOption "Enable ghostty" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.ghostty.enable) {
    programs = {
      ghostty = {
        inherit (cfg.ghostty) enable;
        clearDefaultKeybinds = true;
        enableZshIntegration = config.modules.shell.zsh.enable;
        installVimSyntax = config.modules.editor.nvim.enable;
        settings = {
          theme = "catppuccin-macchiato";
        };
        themes = {
          catppuccin-mocha = {
            palette = [
              "0=#45475a"
              "1=#f38ba8"
              "2=#a6e3a1"
              "3=#f9e2af"
              "4=#89b4fa"
              "5=#f5c2e7"
              "6=#94e2d5"
              "7=#bac2de"
              "8=#585b70"
              "9=#f38ba8"
              "10=#a6e3a1"
              "11=#f9e2af"
              "12=#89b4fa"
              "13=#f5c2e7"
              "14=#94e2d5"
              "15=#a6adc8"
            ];
            background = "1e1e2e";
            foreground = "cdd6f4";
            cursor-color = "f5e0dc";
            selection-background = "353749";
            selection-foreground = "cdd6f4";
          };
          catppuccin-macchiato = {
            palette = [
              "0=#494d64"
              "1=#ed8796"
              "2=#a6da95"
              "3=#eed49f"
              "4=#8aadf4"
              "5=#f5bde6"
              "6=#8bd5ca"
              "7=#b8c0e0"
              "8=#5b6078"
              "9=#ed8796"
              "10=#a6da95"
              "11=#eed49f"
              "12=#8aadf4"
              "13=#f5bde6"
              "14=#8bd5ca"
              "15=#a5adcb"
            ];
            background = "24273a";
            foreground = "cad3f5";
            cursor-color = "f4dbd6";
            selection-background = "3a3e53";
            selection-foreground = "cad3f5";
          };
        };
      };
    };
  };
}
