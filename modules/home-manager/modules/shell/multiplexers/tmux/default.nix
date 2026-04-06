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
        shortcut = "a";
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
          set -ga update-environment HYPRLAND_INSTANCE_SIGNATURE

          # Forward Ctrl+L to the pane so shell clear always works
          bind -n C-l send-keys C-l

          # Forward Ctrl+O to the pane so zsh yazi binding works
          bind -n C-o send-keys C-o

          # Override prefix to Alt+Escape (home-manager sets C-a, we override here)
          set -g prefix M-Escape
          unbind C-a
          bind M-Escape send-prefix

          # ── Prefix-free: pane navigation (Alt+hjkl) ─────────────────────────
          bind -n M-h select-pane -L
          bind -n M-j select-pane -D
          bind -n M-k select-pane -U
          bind -n M-l select-pane -R

          # ── Prefix-free: pane resize (Alt+HJKL) ──────────────────────────────
          bind -n M-H resize-pane -L 5
          bind -n M-J resize-pane -D 5
          bind -n M-K resize-pane -U 5
          bind -n M-L resize-pane -R 5

          # ── Prefix-free: splits ───────────────────────────────────────────────
          bind -n M-v split-window -h -c "#{pane_current_path}"
          bind -n M-x split-window -v -c "#{pane_current_path}"

          # ── Prefix-free: windows ─────────────────────────────────────────────
          bind -n M-t new-window -c "#{pane_current_path}"
          bind -n M-p previous-window
          bind -n M-n next-window
          bind -n M-< swap-window -t -1\; select-window -t -1
          bind -n M-> swap-window -t +1\; select-window -t +1

          # ── Prefix-free: misc ─────────────────────────────────────────────────
          bind -n M-z resize-pane -Z            # zoom/unzoom current pane
          bind -n M-q confirm-before kill-pane  # close pane (with confirm)
          bind -n M-s choose-tree -Zs           # session picker
          bind -n M-e copy-mode                 # enter copy/scroll mode (like Vim visual)

          # ── Prefix bindings (rare operations) ────────────────────────────────
          bind v split-window -h -c "#{pane_current_path}"
          bind s split-window -v -c "#{pane_current_path}"
          bind c new-window -c "#{pane_current_path}"
          bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

          # ── Vi copy mode ──────────────────────────────────────────────────────
          bind-key -T copy-mode-vi v send-keys -X begin-selection
          bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
          bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
          bind-key -T copy-mode-vi Escape send-keys -X cancel

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
