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
  # Rich session list: per session, every pane with its workspace, detected
  # agent and directory (the herdr counterpart of the tmux `tls` alias)
  herdr-ls = pkgs.writeShellApplication {
    name = "herdr-ls";
    runtimeInputs = [pkgs.herdr pkgs.jq];
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
        message = "modules.shell.multiplexers.herdr and modules.shell.multiplexers.tmux both define the tma/tls aliases and auto-start; enable only one of them";
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
      packages = [pkgs.herdr herdr-ls];
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

          # Auto-attach to herdr on terminal start (outside of herdr)
          if [[ -z "$HERDR_ENV" ]] && [[ -n "$DISPLAY" || -n "$WAYLAND_DISPLAY" ]]; then
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

            # Same layout as the tmux module: everyday actions sit directly on
            # Alt, without a prefix. ctrl+b stays as prefix for phones, where
            # Alt is awkward. prefix+[ is hard to reach on a German layout, so
            # copy mode also gets alt+e.
            [keys]
            focus_pane_left = ["prefix+h", "alt+h"]
            focus_pane_down = ["prefix+j", "alt+j"]
            focus_pane_up = ["prefix+k", "alt+k"]
            focus_pane_right = ["prefix+l", "alt+l"]
            resize_pane_left = "alt+shift+h"
            resize_pane_down = "alt+shift+j"
            resize_pane_up = "alt+shift+k"
            resize_pane_right = "alt+shift+l"
            split_vertical = ["prefix+v", "alt+v"]
            split_horizontal = ["prefix+minus", "alt+x"]
            new_tab = ["prefix+c", "alt+t"]
            previous_tab = ["prefix+p", "alt+p"]
            next_tab = ["prefix+n", "alt+n"]
            zoom = ["prefix+z", "alt+z"]
            close_pane = ["prefix+x", "alt+q"]
            goto = ["prefix+g", "alt+s"]
            copy_mode = ["prefix+[", "alt+e"]
          '';
        };
      };
    };
  };
}
