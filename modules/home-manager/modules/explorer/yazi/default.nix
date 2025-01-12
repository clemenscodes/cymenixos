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
        ".config/yazi/plugins/smart-paste.yazi/init.lua" = {
          text =
            /*
            lua
            */
            ''
              --- @sync entry
              return {
              	entry = function()
              		local h = cx.active.current.hovered
              		if h and h.cha.is_dir then
              			ya.manager_emit("enter", {})
              			ya.manager_emit("paste", {})
              			ya.manager_emit("leave", {})
              		else
              			ya.manager_emit("paste", {})
              		end
              	end,
              }
            '';
        };
        ".config/yazi/plugins/smart-tab.yazi/init.lua" = {
          text =
            /*
            lua
            */
            ''
              --- @sync entry
              return {
              	entry = function()
              		local h = cx.active.current.hovered
              		ya.manager_emit("tab_create", h and h.cha.is_dir and { h.url } or { current = true })
              	end,
              }
            '';
        };
        ".config/yazi/plugins/smart-switch.yazi/init.lua" = {
          text =
            /*
            lua
            */
            ''
              --- @sync entry
              local function entry(_, job)
              	local cur = cx.active.current
              	for _ = #cx.tabs, job.args[1] do
              		ya.manager_emit("tab_create", { cur.cwd })
              		if cur.hovered then
              			ya.manager_emit("reveal", { cur.hovered.url })
              		end
              	end
              	ya.manager_emit("tab_switch", { job.args[1] })
              end

              return { entry = entry }
            '';
        };
      };
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
                  run = "plugin smart-switch --args=1";
                  desc = "Switch or create tab 2";
                }
                {
                  on = ["y"];
                  run = ''

                  '';
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
        };
      };
    };
  };
}
