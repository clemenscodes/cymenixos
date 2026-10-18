{
  pkgs,
  lib,
  ...
}: {config, ...}: let
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
          '';
        };
      };
    };
  };
}
