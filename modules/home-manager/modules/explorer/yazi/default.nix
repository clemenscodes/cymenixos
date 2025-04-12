{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.explorer;
  plugins = import ./plugins {inherit pkgs;};
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
      ];
    };
    programs = {
      yazi = {
        inherit (cfg.yazi) enable;
        enableZshIntegration = config.modules.shell.zsh.enable;
        settings = {
          manager = {
            show_hidden = true;
            show_symlink = false;
          };
          plugin = {
            prepend_previewers = [
              {
                name = "*.md";
                run = "glow";
              }
              {
                mime = "text/csv";
                run = "miller";
              }
              {
                mime = "audio/*";
                run = "exifaudio";
              }
              {
                name = "*.bin";
                run = "hexyl";
              }
            ];
            append_previewers = [
              {
                name = "*";
                run = "hexyl";
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
          };
        };
        keymap = {
          manager = {
            prepend_keymap = [
              {
                on = ["!"];
                run = "shell $SHELL --block";
                desc = "Open shell here";
              }
              {
                on = ["l"];
                run = "plugin smart-enter";
                desc = "Enter the child directory, or open the file";
              }
              {
                on = ["p"];
                run = "plugin smart-paste";
                desc = "Paste into the hovered directory or CWD";
              }
              {
                on = ["t"];
                run = "plugin smart-tab";
                desc = "Create a tab and enter the hovered directory";
              }
              {
                on = ["2"];
                run = "plugin smart-switch '1'";
                desc = "Switch or create tab 2";
              }
              {
                on = ["<C-n>"];
                run = "shell '${pkgs.ripdrag}/bin/ripdrag $@ -x 2>/dev/null &' --confirm";
              }
              {
                on = ["g" "r"];
                run = "shell '${pkgs.yazi}/bin/ya emit cd $(git rev-parse --show-toplevel)'";
              }
              {
                on = ["k"];
                run = "plugin arrow '-1'";
              }
              {
                on = ["j"];
                run = "plugin arrow '1'";
              }
              {
                on = ["<C-y>"];
                run = "plugin wl-clipboard";
              }
              {
                on = ["E"];
                run = "plugin eza-preview";
                desc = "Toggle tree/list dir preview";
              }
              {
                on = ["d"];
                run = "shell --confirm 'rm -rf $@'";
                desc = "Remove files instantly";
              }
            ];
          };
          input = {
            prepend_keymap = [
              {
                on = ["<Esc>"];
                run = "close";
                desc = "Cancel input";
              }
            ];
          };
        };
        initLua = ''
          require("starship"):setup()
        '';
        inherit plugins;
      };
    };
  };
}
