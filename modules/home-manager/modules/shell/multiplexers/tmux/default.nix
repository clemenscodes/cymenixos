{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.shell.multiplexers;
in {
  options = {
    modules = {
      shell = {
        multiplexers = {
          tmux = {
            enable = lib.mkEnableOption "Enable tmux" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.tmux.enable) {
    programs = {
      tmux = {
        inherit (cfg.tmux) enable;
        clock24 = true;
        baseIndex = 1;
        keyMode = "vi";
        shortcut = "Space";
        customPaneNavigationAndResize = true;
        disableConfirmationPrompt = true;
        mouse = true;
        shell = "${pkgs.zsh}/bin/zsh";
        sensibleOnTop = true;
        escapeTime = 0;
        terminal = "xterm-kitty";
        plugins = [
          pkgs.tmuxPlugins.vim-tmux-navigator
          pkgs.tmuxPlugins.catppuccin
          pkgs.tmuxPlugins.yank
        ];
        extraConfig = ''
          set -as terminal-features ",xterm-kitty:RGB"
          bind '"' split-window -v -c "#{pane_current_path}"
          bind % split-window -h -c "#{pane_current_path}"
        '';
      };
    };
  };
}
