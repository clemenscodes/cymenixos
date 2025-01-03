{
  pkgs,
  lib,
  ...
}: {
  config,
  osConfig,
  ...
}: let
  cfg = config.modules.shell;
  user = osConfig.modules.users.user;
  username = osConfig.modules.users.name;
  flake = osConfig.modules.users.flake;
  machine = osConfig.modules.machine.name;
  useLf = config.modules.explorer.lf.enable;
  useYazi = config.modules.explorer.yazi.enable;
  explorer =
    if useLf
    then "lfcd"
    else if useYazi
    then "yazicd"
    else "${explorer}";
in {
  options = {
    modules = {
      shell = {
        zsh = {
          enable = lib.mkEnableOption "Enable a great zsh" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.zsh.enable) {
    home = {
      packages = [
        (import ./scripts/boot.nix {inherit pkgs;})
        (import ./scripts/build.nix {inherit pkgs username machine;})
        (import ./scripts/buildprofile.nix {inherit pkgs username machine;})
        (import ./scripts/buildprofile-user.nix {inherit pkgs username;})
        (import ./scripts/clean.nix {inherit pkgs;})
        (import ./scripts/nb.nix {inherit pkgs config;})
        (import ./scripts/nd.nix {inherit pkgs config;})
        (import ./scripts/nixdiff.nix {inherit pkgs;})
        (import ./scripts/ns.nix {inherit pkgs config;})
        (import ./scripts/sw.nix {inherit pkgs;})
        (import ./scripts/sw-user.nix {inherit pkgs;})
        (import ./scripts/switch.nix {inherit pkgs;})
        (import ./scripts/swupdate.nix {inherit pkgs;})
        (import ./scripts/tracewarning.nix {inherit pkgs;})
      ];
      sessionVariables = {
        FLAKE = "${config.home.homeDirectory}/${flake}";
        NIXOS_OZONE_WL = 1;
        ANDROID_USER_HOME = "$HOME/.local/share/android";
        CARGO_HOME = "$HOME/.local/share/cargo";
        GOPATH = "$HOME/.local/share/go";
        MBSYNCRC = "$HOME/.config/mbsync/config";
        M2_HOME = "$HOME/.local/share/m2";
        CUDA_CACHE_PATH = "$HOME/.cache/nv";
        WINEPREFIX = "$HOME/.local/share/wine";
        LD_LIBRARY_PATH = "/run/opengl-driver/lib:$LD_LIBRARY_PATH";
        JAVA_HOME = "/etc/profiles/per-user/${user}";
        EXPLORER = "${explorer}";
      };
    };
    programs = {
      zsh = {
        inherit (cfg.zsh) enable;
        enableCompletion = true;
        syntaxHighlighting = {
          enable = true;
        };
        autosuggestion = {
          enable = true;
        };
        autocd = true;
        completionInit = true;
        oh-my-zsh = {
          enable = true;
          plugins = [
            "git"
            "git-flow"
            "systemd"
            "colored-man-pages"
            "colorize"
          ];
        };
        dotDir = ".config/zsh";
        shellAliases = {
          sudo = "sudo ";
          update = "cd $MOON && git pull origin $(git_current_branch)";
          src = "omz reload";
          ssh = "kitten ssh";
          ls = "${pkgs.eza}/bin/eza";
          ne = "${explorer} $MOON";
          nehm = "${explorer} $MOON/nix/modules/home-manager/modules";
          nenvim = "${explorer} $MOON/nix/modules/home-manager/modules/editor/nixvim";
          notes = "${explorer} $MOON/notes";
          nix-repl-flake = ''nix repl --expr "builtins.getFlake \"$PWD\""'';
          V = "${explorer} $XDG_VIDEOS_DIR";
          D = "${explorer} $XDG_DOWNLOAD_DIR";
          M = "${explorer} $XDG_MUSIC_DIR";
          I = "${explorer} $XDG_PICTURES_DIR";
          S = "${explorer} $XDG_PICTURES_DIR/screenshots";
          docs = "${explorer} $XDG_DOCUMENTS_DIR";
          isos = "${explorer} $XDG_DATA_HOME/isos";
          rr = "${explorer} $HOME/.local/src";
          ma = "${explorer} $HOME/.local/src/master/semester/1";
        };
        history = {
          path = "${config.xdg.dataHome}/zsh/zsh_history";
        };
        historySubstringSearch = {
          enable = true;
        };
        initExtraBeforeCompInit = ''
          autoload -U colors && colors
        '';
        initExtra =
          /*
          bash
          */
          ''
            zstyle ':completion*' menu select
            bindkey -v
            bindkey -M menuselect 'h' vi-backward-char
            bindkey -M menuselect 'k' vi-up-line-or-history
            bindkey -M menuselect 'l' vi-forward-char
            bindkey -M menuselect 'j' vi-down-line-or-history
            bindkey -v '^?' backward-delete-char
            function zle-keymap-select () {
                case $KEYMAP in
                    vicmd) echo -ne '\e[1 q';;
                    viins|main) echo -ne '\e[5 q';;
                esac
            }
            zle -N zle-keymap-select
            zle-line-init() {
                zle -K viins
                echo -ne "\e[5 q"
            }
            zle -N zle-line-init
            echo -ne '\e[5 q'
            preexec() { echo -ne '\e[5 q' ;}
            lfcd () {
                tmp="$(mktemp -uq)"
                trap 'rm -f $tmp >/dev/null 2>&1' HUP INT QUIT TERM PWR EXIT
                lf -last-dir-path="$tmp" "$@"
                if [ -f "$tmp" ]; then
                    dir="$(cat "$tmp")"
                    [ -d "$dir" ] && [ "$dir" != "$(pwd)" ] && cd "$dir"
                fi
            }
            yazicd () {
              local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
              yazi "$@" --cwd-file="$tmp"
              if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
              	cd -- "$cwd"
              fi
              rm -f -- "$tmp"
            }
            bindkey -s '^o' '${explorer}\n'
            autoload edit-command-line; zle -N edit-command-line
            bindkey '^e' edit-command-line
            bindkey -M vicmd '^[[P' vi-delete-char
            bindkey -M vicmd '^e' edit-command-line
            bindkey -M visual '^[[P' vi-delete
            eval "$(direnv hook zsh)"
            export ZSH_CACHE_DIR
          '';
        profileExtra =
          /*
          bash
          */
          ''
            export LESS=-R
            export LESS_TERMCAP_mb="$(printf '%b' '[1;31m')"
            export LESS_TERMCAP_md="$(printf '%b' '[1;36m')"
            export LESS_TERMCAP_me="$(printf '%b' '[0m')"
            export LESS_TERMCAP_so="$(printf '%b' '[01;44;33m')"
            export LESS_TERMCAP_se="$(printf '%b' '[0m')"
            export LESS_TERMCAP_us="$(printf '%b' '[1;32m')"
            export LESS_TERMCAP_ue="$(printf '%b' '[0m')"
          ''
          + "${
            if osConfig.modules.wsl.enable
            then ''
              export WINHOME=/mnt/c/Users/${username}
              export WINMUSIC=$WINHOME/Music
              export WINVIDEOS=$WINHOME/Videos
              export WINDOCUMENTS=$WINHOME/Documents
              export WINDOWNLOADS=$WINHOME/Downloads
              export WINPICTURES=$WINHOME/Pictures
            ''
            else ""
          }";
      };
    };
  };
}
