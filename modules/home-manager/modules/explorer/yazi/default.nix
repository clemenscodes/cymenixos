{
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
          # save a file
          set -- --chooser-file="$out" "$path"
      elif [ "$directory" = "1" ]; then
          # upload files from a directory
          set -- --chooser-file="$out" --cwd-file="$out" "$path"
      elif [ "$multiple" = "1" ]; then
          # upload multiple files
          set -- --chooser-file="$out" "$path"
      else
          # upload only 1 file
          set -- --chooser-file="$out" "$path"
      fi

      command="$termcmd $cmd"
      for arg in "$@"; do
          # escape double quotes
          escaped="$(printf "%s" "$arg" | sed 's/"/\\"/g')"
          # escape spaces
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
        pkgs.miller
        pkgs.glow
        pkgs.hexyl
        pkgs.eza
        yazi-cwd
        # pkgs.xdg-desktop-portal-termfilechooser
      ];
    };
    # xdg = {
    #   configFile = {
    #     "xdg-desktop-portal-termfilechooser/config" = {
    #       text = ''
    #         [filechooser]
    #         cmd=${lib.getExe yazi-termfilechooser-wrapper}
    #         default_dir=$HOME
    #       '';
    #     };
    #   };
    #   portal = {
    #     extraPortals = [pkgs.xdg-desktop-portal-termfilechooser];
    #     config = {
    #       common = {
    #         "org.freedesktop.impl.portal.FileChooser" = "termfilechooser";
    #       };
    #     };
    #   };
    # };
    programs = {
      yazi = {
        inherit (cfg.yazi) enable;
        enableZshIntegration = config.modules.shell.zsh.enable;
        plugins = {
          inherit (pkgs.yaziPlugins) smart-enter;
        };
        settings = {
          manager = {
            show_hidden = true;
            show_symlink = false;
          };
        };
        keymap = {
          manager = {
            prepend_keymap = [
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
