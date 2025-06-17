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

  hexyl = pkgs.stdenv.mkDerivation {
    name = "hexyl.yazi";
    src = inputs.hexyl-yazi;
    installPhase = ''
      mkdir -p $out
      cp $src/* $out
    '';
  };
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
        pkgs.miller
        pkgs.glow
        pkgs.hexyl
        pkgs.eza
        yazi-cwd
        pkgs.xdg-desktop-portal-termfilechooser
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
            require("full-border"):setup {
              -- Available values: ui.Border.PLAIN, ui.Border.ROUNDED
              type = ui.Border.ROUNDED,
            }
          '';
        enableZshIntegration = config.modules.shell.zsh.enable;
        plugins = {
          inherit
            (pkgs.yaziPlugins)
            smart-enter
            git
            lazygit
            full-border
            ;
          inherit hexyl;
        };
        settings = {
          mgr = {
            show_hidden = true;
            show_symlink = false;
          };
          plugin = {
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
            append_previewers = [
              {
                name = "*";
                run = "hexyl";
              }
            ];
          };
        };
        keymap = {
          mgr = {
            prepend_keymap = [
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
            ];
          };
        };
      };
    };
  };
}
