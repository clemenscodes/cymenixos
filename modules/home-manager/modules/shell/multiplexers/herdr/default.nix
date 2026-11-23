{
  pkgs,
  lib,
  ...
}: {
  osConfig,
  config,
  ...
}: let
  cfg = config.modules.shell.multiplexers;
  # A client started with HERDR_ATTACH_TAB views that tab, while every other
  # client keeps its own view. Upstream herdr can only focus a tab for all
  # clients at once.
  herdr = pkgs.herdr.overrideAttrs (old: {
    patches = (old.patches or []) ++ [./attach-tab.patch];
  });
  # Rich session list: per session, every pane with its workspace, detected
  # agent and directory (the herdr counterpart of the tmux `tls` alias)
  herdr-ls = pkgs.writeShellApplication {
    name = "herdr-ls";
    runtimeInputs = [herdr pkgs.jq];
    text = ''
      herdr session list --json | jq -r '.sessions[] | [.name, .running] | @tsv' |
        while IFS=$'\t' read -r name running; do
          if [ "$running" != true ]; then
            echo "$name: (stopped)"
            continue
          fi
          echo "$name:"
          herdr --session "$name" api snapshot | jq -r '
            .result.snapshot as $snap
            | ($snap.workspaces | map({key: .workspace_id, value: .label}) | from_entries) as $ws
            | $snap.panes[]
            | "  \($ws[.workspace_id]) [\(.display_agent // .agent // "shell")] \(.foreground_cwd // .cwd)"
          '
        done
    '';
  };
in {
  options = {
    modules = {
      shell = {
        multiplexers = {
          herdr = {
            enable = lib.mkEnableOption "Enable herdr" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.herdr.enable) {
    assertions = [
      {
        assertion = !cfg.tmux.enable;
        message = "modules.shell.multiplexers.herdr and modules.shell.multiplexers.tmux both define the tma/tls aliases; enable only one of them";
      }
    ];
    home = {
      # .config/herdr holds the saved session layout, .local/state/herdr the
      # saved SSH machines. Without these a reboot forgets both.
      persistence = lib.mkIf osConfig.modules.boot.enable {
        "${osConfig.modules.boot.impermanence.persistPath}" = {
          directories = [
            ".config/herdr"
            ".local/state/herdr"
          ];
        };
      };
      packages = [herdr herdr-ls];
    };
    programs = {
      zsh = {
        shellAliases = {
          tls = "herdr-ls";
        };
        initContent = lib.mkAfter ''
          # Attach a session by name, e.g. `tma work`; without a name attach the
          # default session. Unlike `tmux attach`, herdr creates a missing session.
          tma() {
            if (( $# )); then
              herdr session attach "$1"
            else
              herdr
            fi
          }

          # Panes inherit the environment of the herdr server, not of the
          # window they show in. A server started over ssh has no display, so
          # nothing in its panes reaches the clipboard, pasting images included.
          # Such a pane takes the display whose socket is there.
          if [[ -n "$HERDR_PANE_ID" && -z "$WAYLAND_DISPLAY" ]]; then
            for socket in "$XDG_RUNTIME_DIR"/wayland-<->(N=); do
              export WAYLAND_DISPLAY=$socket:t
              break
            done
            for socket in /tmp/.X11-unix/X<->(N=); do
              export DISPLAY=:''${socket:t:s/X/}
              break
            done
          fi

          # A new graphical terminal attaches the running session. When the
          # session already runs, it gets a workspace of its own in the
          # directory it opened in, like alt+enter, shown only in this window;
          # the other windows keep what they show. Without a running server
          # plain `herdr` starts one.
          if [[ -z "$HERDR_PANE_ID" ]] && [[ -n "$DISPLAY" || -n "$WAYLAND_DISPLAY" ]]; then
            if herdr status server 2>/dev/null | grep -q '^status: running$'; then
              HERDR_ATTACH_TAB=$(herdr workspace create --cwd "$PWD" --no-focus | ${lib.getExe pkgs.jq} -r '.result.tab.tab_id') exec herdr
            fi
            exec herdr
          fi
        '';
      };
    };
    xdg = {
      configFile = {
        "herdr/config.toml" = {
          text = ''
            onboarding = false

            [theme]
            name = "catppuccin"

            [update]
            version_check = false

            # Only the tab bar on top; alt+b brings the sidebar back.
            [ui]
            sidebar_start_collapsed = true
            sidebar_collapsed_mode = "hidden"

            # Every prefix binding also sits on Alt with the same key, so ctrl+b
            # is only needed on phones, where Alt is awkward. Where Alt already
            # has its own job (pane cycling on hjkl, tabs on tab, close on q,
            # goto on s, copy mode on e, split down on x, zoom on f), that wins
            # and the action keeps only its prefix binding. prefix+n/p and
            # prefix+z are not mirrored on purpose.
            [keys]
            navigate_workspace_up = "k"
            navigate_workspace_down = "j"
            help = ["prefix+?", "alt+?"]
            new_workspace = ["prefix+shift+n", "alt+shift+n", "alt+enter"]
            new_worktree = ["prefix+shift+g", "alt+shift+g"]
            rename_workspace = ["prefix+shift+w", "alt+shift+w"]
            close_workspace = ["prefix+shift+d", "alt+shift+d"]
            reload_config = ["prefix+shift+r", "alt+shift+r"]
            open_notification_target = ["prefix+o", "alt+o"]
            rename_tab = ["prefix+shift+t", "alt+shift+t"]
            close_tab = ["prefix+shift+x", "alt+shift+x"]
            rename_pane = ["prefix+shift+p", "alt+shift+p"]
            resize_mode = ["prefix+r", "alt+r"]
            toggle_sidebar = ["prefix+b", "alt+b"]
            workspace_picker = ["prefix+w", "alt+w"]
            switch_tab = ["prefix+1..9", "alt+1..9"]
            # Directional focus stops at the edge, cycling wraps around, so
            # Alt+hjkl cycles: with two panes every direction reaches the other.
            cycle_pane_next = ["prefix+tab", "alt+j", "alt+l"]
            cycle_pane_previous = ["prefix+shift+tab", "alt+k", "alt+h"]
            resize_pane_left = "alt+shift+h"
            resize_pane_down = "alt+shift+j"
            resize_pane_up = "alt+shift+k"
            resize_pane_right = "alt+shift+l"
            split_vertical = ["prefix+v", "alt+v"]
            split_horizontal = ["prefix+minus", "alt+minus", "alt+x"]
            new_tab = ["prefix+c", "alt+c"]
            previous_tab = ["prefix+p", "alt+shift+tab"]
            previous_agent = "alt+shift+a"
            next_tab = ["prefix+n", "alt+tab"]
            next_agent = "alt+a"
            zoom = ["prefix+z", "alt+f"]
            close_pane = ["prefix+x", "alt+q"]
            goto = ["prefix+g", "alt+g", "alt+s"]
            copy_mode = ["prefix+[", "alt+[", "alt+e"]
          '';
        };
      };
    };
  };
}
