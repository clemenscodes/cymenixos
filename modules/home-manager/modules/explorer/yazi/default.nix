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
                run = "plugin smart-switch --args=1";
                desc = "Switch or create tab 2";
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
          require("full-border"):setup {
          	type = ui.Border.ROUNDED,
          }

          THEME.git = THEME.git or {}
          THEME.git.modified = ui.Style():fg("blue")
          THEME.git.deleted = ui.Style():fg("red"):bold()
          require("git"):setup()
        '';
        plugins = {
          inherit (plugins) full-border git smart-enter smart-paste smart-switch smart-tab;
        };
      };
    };
  };
}
