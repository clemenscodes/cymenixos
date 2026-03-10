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
        historyLimit = 50000;
        plugins = [
          {
            plugin = pkgs.tmuxPlugins.catppuccin;
            extraConfig = ''
              set -g @catppuccin_flavor 'macchiato'
              set -g @catppuccin_window_status_style 'rounded'
              set -g @catppuccin_window_number_position 'right'
              set -g @catppuccin_window_default_fill 'number'
              set -g @catppuccin_window_default_text '#W'
              set -g @catppuccin_window_current_fill 'number'
              set -g @catppuccin_window_current_text '#W#{?window_zoomed_flag, ,}'
              set -g @catppuccin_status_modules_right 'directory session date_time'
              set -g @catppuccin_status_left_separator ''
              set -g @catppuccin_status_right_separator ''
              set -g @catppuccin_status_fill 'icon'
              set -g @catppuccin_status_connect_separator 'no'
              set -g @catppuccin_directory_text '#{pane_current_path}'
              set -g @catppuccin_date_time_text '%H:%M'
            '';
          }
          pkgs.tmuxPlugins.yank
          {
            plugin = pkgs.tmuxPlugins.resurrect;
            extraConfig = ''
              set -g @resurrect-strategy-nvim 'session'
              set -g @resurrect-capture-pane-contents 'on'
            '';
          }
          {
            plugin = pkgs.tmuxPlugins.continuum;
            extraConfig = ''
              set -g @continuum-restore 'on'
              set -g @continuum-save-interval '10'
            '';
          }
        ];
        extraConfig = ''
          # Terminal features
          set -as terminal-features ",xterm-kitty:RGB"
          set -g focus-events on

          # Ensure Ctrl+L is never intercepted (clear screen must always work)
          unbind -n C-l

          # Intuitive splits that preserve current directory
          bind | split-window -h -c "#{pane_current_path}"
          bind - split-window -v -c "#{pane_current_path}"
          bind '"' split-window -v -c "#{pane_current_path}"
          bind % split-window -h -c "#{pane_current_path}"

          # Prefix-free pane navigation with Alt+hjkl (no Ctrl+L conflict)
          bind -n M-h select-pane -L
          bind -n M-j select-pane -D
          bind -n M-k select-pane -U
          bind -n M-l select-pane -R

          # Prefix-free pane resize with Alt+HJKL
          bind -n M-H resize-pane -L 5
          bind -n M-J resize-pane -D 5
          bind -n M-K resize-pane -U 5
          bind -n M-L resize-pane -R 5

          # Window navigation
          bind -n M-[ previous-window
          bind -n M-] next-window

          # Move windows left/right
          bind -n M-< swap-window -t -1\; select-window -t -1
          bind -n M-> swap-window -t +1\; select-window -t +1

          # Session picker
          bind -n M-s choose-tree -Zs

          # New window in current directory
          bind c new-window -c "#{pane_current_path}"

          # Vi copy mode bindings
          bind-key -T copy-mode-vi v send-keys -X begin-selection
          bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
          bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
          bind-key -T copy-mode-vi Escape send-keys -X cancel

          # Reload config
          bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

          # Status bar at top
          set -g status-position top

          # Renumber windows when one is closed
          set -g renumber-windows on

          # Keep custom window names
          set -g allow-rename off
          set -g automatic-rename off

          # Don't exit tmux when closing last pane
          set -g detach-on-destroy off
        '';
      };
    };
  };
}
