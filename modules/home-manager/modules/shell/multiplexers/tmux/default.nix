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
      zsh = {
        initContent = lib.mkAfter ''
          # Auto-attach to tmux session on terminal start (outside of tmux)
          if [[ -z "$TMUX" ]] && [[ -n "$DISPLAY" || -n "$WAYLAND_DISPLAY" ]]; then
            exec tmux new-session
          fi
        '';
      };
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
        escapeTime = 10;
        terminal = "tmux-256color";
        historyLimit = 50000;
        plugins = [
          {
            plugin = pkgs.tmuxPlugins.catppuccin;
            extraConfig = ''
              set -g @catppuccin_flavor 'macchiato'
              set -g @catppuccin_window_status_style 'rounded'
              set -g @catppuccin_window_default_fill 'number'
              set -g @catppuccin_window_default_text '#W'
              set -g @catppuccin_window_current_fill 'number'
              set -g @catppuccin_window_current_text '#W#{?window_zoomed_flag, ,}'
              set -g @catppuccin_status_modules_right ""
              set -g @catppuccin_status_modules_left ""
              set -g @catppuccin_status_left_separator ""
              set -g @catppuccin_status_right_separator ""
            '';
          }
          pkgs.tmuxPlugins.yank
        ];
        extraConfig = ''
          # Terminal features
          set -as terminal-features ",xterm-kitty:RGB"
          set -g focus-events on

          # Extended key protocol — fixes Neovim input lag and key combo recognition
          set -g extended-keys on
          set -as terminal-features ",xterm-kitty:extkeys"

          # Allow kitty graphics protocol to pass through tmux to the terminal
          # (prevents yazi from falling back to tmux-popup image previews)
          set -g allow-passthrough on
          set -ga update-environment TERM
          set -ga update-environment TERM_PROGRAM

          # Forward Ctrl+L to the pane so shell clear always works
          bind -n C-l send-keys C-l

          # Forward Ctrl+O to the pane so zsh yazi binding works
          bind -n C-o send-keys C-o

          # Letter-based splits (keyboard-layout agnostic)
          bind v split-window -h -c "#{pane_current_path}"
          bind s split-window -v -c "#{pane_current_path}"

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

          # Window navigation (avoid M-[ / M-] — they collide with CSI escape sequences)
          bind -n M-p previous-window
          bind -n M-n next-window

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

          # Minimal status bar — windows only, no right/left content
          set -g status-right ""
          set -g status-left ""
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
