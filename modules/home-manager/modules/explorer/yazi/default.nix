{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.explorer;
  yazi-termfilechooser-wrapper = pkgs.writeShellApplication {
    name = "yazi-termfilechooser-wrapper";
    runtimeInputs = [
      pkgs.yazi
      pkgs.gnused
      pkgs.kitty
    ];
    text = ''
      multiple="$1"
      directory="$2"
      save="$3"
      path="$4"
      out="$5"

      cmd="yazi"
      termcmd="''${TERMCMD:-kitty --title 'termfilechooser'}"

      if [ "$save" = "1" ]; then
          set -- --chooser-file="$out" "$path"
      elif [ "$directory" = "1" ]; then
          set -- --chooser-file="$out" --cwd-file="$out" "$path"
      elif [ "$multiple" = "1" ]; then
          set -- --chooser-file="$out" "$path"
      else
          set -- --chooser-file="$out" "$path"
      fi

      command="$termcmd $cmd"
      for arg in "$@"; do
          escaped="$(printf "%s" "$arg" | sed 's/"/\\"/g')"
          command="$command \"$escaped\""
      done

      sh -c "$command"
    '';
  };
  yazi-cwd = pkgs.writeShellScriptBin "y" ''
    function y() {
    	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    	yazi "$@" --cwd-file="$tmp"
    	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    		builtin cd -- "$cwd"
    	fi
    	rm -f -- "$tmp"
    }
    y "$@"
  '';
in {
  options = {
    modules = {
      explorer = {
        yazi = {
          enable = lib.mkEnableOption "Enable yazi file browser" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.yazi.enable) {
    home = {
      packages = [
        pkgs.file
        pkgs.ffmpegthumbnailer
        pkgs.unar
        pkgs.poppler
        pkgs.jq
        pkgs.fd
        pkgs.ripgrep
        pkgs.fzf
        pkgs.zoxide
        pkgs.wl-clipboard
        pkgs.exiftool
        pkgs.mediainfo
        pkgs.glow
        pkgs.hexyl
        pkgs.eza
        yazi-cwd
        pkgs.xdg-desktop-portal-termfilechooser
        pkgs.rsync
      ];
    };
    xdg = {
      configFile = {
        "xdg-desktop-portal-termfilechooser/config" = {
          text = ''
            [filechooser]
            cmd=${lib.getExe yazi-termfilechooser-wrapper}
            default_dir=$HOME
          '';
        };
        "yazi/theme.toml" = {
          source = ./theme.toml;
        };
        "yazi/Catppuccin-macchiato.tmTheme" = {
          source = ./Catppuccin-macchiato.tmTheme;
        };
      };
      portal = {
        extraPortals = [pkgs.xdg-desktop-portal-termfilechooser];
        config = {
          common = {
            "org.freedesktop.impl.portal.FileChooser" = "termfilechooser";
          };
        };
      };
    };
    programs = {
      yazi = {
        inherit (cfg.yazi) enable;
        initLua =
          # Lua
          ''
            require("git"):setup()
            require("starship"):setup()
            require("full-border"):setup({ type = ui.Border.ROUNDED })
            Status:children_add(function(self)
              local h = self._current.hovered
              if h and h.link_to then
                return " -> " .. tostring(h.link_to)
              else
                return ""
              end
            end, 3300, Status.LEFT)
            Status:children_add(function()
              local h = cx.active.current.hovered
              if not h or ya.target_family() ~= "unix" then
                return ""
              end

              return ui.Line {
                ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("magenta"),
                ":",
                ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("magenta"),
                " ",
              }
            end, 500, Status.RIGHT)
            if os.getenv("NVIM") then
              require("toggle-pane"):entry("min-preview")
            end
          '';
        enableZshIntegration = config.modules.shell.zsh.enable;
        plugins = {
          inherit
            (pkgs.yaziPlugins)
            smart-enter
            git
            lazygit
            full-border
            starship
            toggle-pane
            mediainfo
            rsync
            piper
            ;
        };
        settings = {
          mgr = {
            show_hidden = true;
            show_symlink = false;
          };
          preview = {
            max_width = 1000;
            max_height = 1000;
            image_delay = 0;
          };
          plugin = {
            prepend_preloaders = [
              {
                mime = "{audio,video,image}/*";
                run = "mediainfo";
              }
              {
                mime = "application/subrip";
                run = "mediainfo";
              }
            ];
            prepend_fetchers = [
              {
                id = "git";
                name = "*";
                run = "git";
              }
              {
                id = "git";
                name = "*/";
                run = "git";
              }
            ];
            prepend_previewers = [
              {
                name = "*.tar*";
                run = ''piper --format=url -- tar tf "$1"'';
              }
              {
                name = "*.csv";
                run = ''piper -- bat -p --color=always "$1"'';
              }
              {
                name = "*.md";
                run = ''piper -- CLICOLOR_FORCE=1 glow -w=$w -s=dark "$1"'';
              }
              {
                mime = "{audio,video,image}/*";
                run = "mediainfo";
              }
              {
                mime = "application/subrip";
                run = "mediainfo";
              }
            ];
            append_previewers = [
              {
                name = "*";
                run = ''piper -- hexyl --border=none --terminal-width=$w "$1"'';
              }
            ];
          };
        };
        keymap = {
          mgr = {
            prepend_keymap = [
              {
                on = "y";
                run = [''shell -- for path in "$@"; do echo "file://$path"; done | wl-copy -t text/uri-list'' "yank"];
              }
              {
                on = ["g" "i"];
                run = "plugin lazygit";
                desc = "run lazygit";
              }
              {
                on = ["l"];
                run = "plugin smart-enter";
                desc = "Enter the child directory, or open the file";
              }
              {
                on = ["<C-y>"];
                run = "plugin wl-clipboard";
              }
              {
                on = ["d"];
                run = "shell --confirm 'rm -rf $@'";
                desc = "Remove files instantly";
              }
              {
                on = ["T"];
                run = "plugin toggle-pane max-preview";
                desc = "Maximize or restore the preview pane";
              }
              {
                on = ["R"];
                run = "plugin rsync";
                desc = "Copy files using rsync";
              }
            ];
          };
        };
      };
    };
  };
}
