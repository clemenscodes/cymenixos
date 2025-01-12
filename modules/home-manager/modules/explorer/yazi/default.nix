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
                on = ["!"];
                run = '''shell "$SHELL" --block''''';
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
                run = "plugin smart-switch --args=1";
                desc = "Switch or create tab 2";
              }
              {
                on = ["<C-n>"];
                run = "shell '${pkgs.ripdrap}/bin/ripdrag $@ -x 2>/dev/null &' --confirm";
              }
              {
                on = ["g" "r"];
                run = "shell '${pkgs.yazi}/bin/ya emit cd $(git rev-parse --show-toplevel)'";
              }
              {
                on = ["k"];
                run = "plugin arrow --args=-1";
              }
              {
                on = ["j"];
                run = "plugin arrow --args=1";
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

          Status:children_add(function()
          	local h = cx.active.current.hovered
          	if h == nil or ya.target_family() ~= "unix" then
          		return ""
          	end
          
          	return ui.Line {
          		ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("magenta"),
          		":",
          		ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("magenta"),
          		" ",
          	}
          end, 500, Status.RIGHT)

          Header:children_add(function()
          	if ya.target_family() ~= "unix" then
          		return ""
          	end
          	return ui.Span(ya.user_name() .. "@" .. ya.host_name() .. ":"):fg("blue")
          end, 500, Header.LEFT)
        '';
        plugins = {
          inherit
            (plugins)
            arrow
            full-border
            git
            smart-enter
            smart-paste
            smart-switch
            smart-tab
            ;
        };
      };
    };
  };
}
