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
        ".config/yazi/keymap.toml" = {
          text =
            /*
            toml
            */
            ''
              [[manager.prepend_keymap]]
              on   = [ "l" ]
              run  = "plugin smart-enter"
              desc = "Enter the child directory, or open the file"
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
            "[manager.prepend_keymap]" = {
              on = ["l"];
              run = "plugin smart-enter";
              desc = "Enter the child directory, or open the file";
            };
          };
        };
      };
    };
  };
}
