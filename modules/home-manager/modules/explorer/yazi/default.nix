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
      file = {
        ".config/yazi/init.lua" = {
          text = ''
            require("full-border"):setup {
            	type = ui.Border.ROUNDED,
            }
          '';
        };
        ".config/yazi/plugins/smart-enter.yazi/init.lua" = {
          text =
            /*
            lua
            */
            ''
              --- @sync entry
              return {
              	entry = function()
              		local h = cx.active.current.hovered
              		ya.manager_emit(h and h.cha.is_dir and "enter" or "open", { hovered = true })
              	end,
              }
            '';
        };
        ".config/yazi/plugins/full-border.yazi/init.lua" = {
          text =
            /*
            lua
            */
            ''
              local function setup(_, opts)
              	local type = opts and opts.type or ui.Border.ROUNDED
              	local old_build = Tab.build

              	Tab.build = function(self, ...)
              		local bar = function(c, x, y)
              			if x <= 0 or x == self._area.w - 1 then
              				return ui.Bar(ui.Bar.TOP)
              			end

              			return ui.Bar(ui.Bar.TOP)
              				:area(
              					ui.Rect { x = x, y = math.max(0, y), w = ya.clamp(0, self._area.w - x, 1), h = math.min(1, self._area.h) }
              				)
              				:symbol(c)
              		end

              		local c = self._chunks
              		self._chunks = {
              			c[1]:pad(ui.Pad.y(1)),
              			c[2]:pad(ui.Pad(1, c[3].w > 0 and 0 or 1, 1, c[1].w > 0 and 0 or 1)),
              			c[3]:pad(ui.Pad.y(1)),
              		}

              		local style = THEME.manager.border_style
              		self._base = ya.list_merge(self._base or {}, {
              			ui.Border(ui.Border.ALL):area(self._area):type(type):style(style),
              			ui.Bar(ui.Bar.RIGHT):area(self._chunks[1]):style(style),
              			ui.Bar(ui.Bar.LEFT):area(self._chunks[3]):style(style),

              			bar("┬", c[1].right - 1, c[1].y),
              			bar("┴", c[1].right - 1, c[1].bottom - 1),
              			bar("┬", c[2].right, c[2].y),
              			bar("┴", c[2].right, c[2].bottom - 1),
              		})

              		old_build(self, ...)
              	end
              end

              return { setup = setup }
            '';
        };
      };
    };
    programs = {
      yazi = {
        inherit (cfg.yazi) enable;
        settings = {
          manager = {
            show_hidden = true;
            show_symlink = false;
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
                  on = ["!"];
                  run = "shell $SHELL --block";
                  desc = "Open shell here";
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
        };
      };
    };
  };
}
