{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.explorer;
in {
  options = {
    modules = {
      explorer = {
        lf = {
          enable = lib.mkEnableOption "Enable lf file browser" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.lf.enable) {
    xdg = {
      configFile = {
        ctpv = {
          source = ./config/ctpv;
          recursive = true;
        };
        lf = {
          source = ./config;
          recursive = true;
        };
      };
    };
    home = {
      packages = [
        pkgs.file
        pkgs.colordiff
        pkgs.fontforge
        pkgs.ffmpeg
        pkgs.ffmpegthumbnailer
        pkgs.transmission
        pkgs.poppler_utils
        pkgs.jq
        pkgs.chafa
        pkgs.gnupg
        pkgs.imagemagick_light
        pkgs.atool
        pkgs.glow
        pkgs.ctpv
      ];
    };
    programs = {
      lf = {
        enable = cfg.lf.enable;
        settings = {
          hidden = true;
          icons = true;
          preview = true;
          sixel = true;
          ignorecase = true;
          drawbox = true;
          ifs = ''\n'';
          scrolloff = 10;
          period = 1;
        };
        commands = {
          open = ''
            ''${{
              case $(file --mime-type "$(readlink -f $f)" -b) in
                application/pdf | application/vnd* | application/epub*) ${pkgs.util-linux}/bin/setsid -f ${pkgs.zathura}/bin/zathura $fx >/dev/null 2>&1 ;;
                audio/*) ${pkgs.mpv}/bin/mpv --audio-display=no $f ;;
                image/*) swayimg $f ;;
                video/*) ${pkgs.util-linux}/bin/setsid -f ${pkgs.mpv}/bin/mpv $f -quiet >/dev/null 2>&1 ;;
                text/* | application/* | inode/x-empty) $EDITOR $fx ;;
                *) for f in $fx; do ${pkgs.util-linux}/bin/setsid -f $OPENER $f >/dev/null 2>&1; done;;
              esac
            }}
          '';
          delete = ''
            ''${{
              ${pkgs.ncurses}/bin/clear; ${pkgs.ncurses}/bin/tput cup $(($(tput lines)/3)); tput bold
              set -f
              ${pkgs.toybox}/bin/printf "%s\n\t" "$fx"
              ${pkgs.toybox}/bin/printf "delete ? [y/N]"
              read ans
              [ $ans = "y" ] && rm -rf -- $fx
            }}
          '';
          mkdir = ''
            ''${{
              printf "Directory Name: "
              read DIR
              ${pkgs.toybox}/bin/mkdir $DIR
            }}
          '';
        };
        keybindings = {
          V = "push :!nvim<space>";
          W = ''$setsid -f $TERMINAL >/dev/null 2>&1'';
          D = "delete";
          "<c-n>" = "mkdir";
          "<c-r>" = "reload";
          "<enter>" = "shell";
        };
        previewer = {
          source = "${pkgs.ctpv}/bin/ctpv";
        };
        extraConfig = ''
          &${pkgs.ctpv}/bin/ctpv -s $id
          cmd on-quit %${pkgs.ctpv}/bin/ctpv -e $id
          set cleaner ${pkgs.ctpv}/bin/ctpvclear
          set shellopts '-eu'
        '';
      };
    };
  };
}
