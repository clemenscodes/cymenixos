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
        pkgs.exiftool
        pkgs.mediainfo
        pkgs.miller
        pkgs.glow
        pkgs.hexyl
        pkgs.eza
        pkgs.xdg-desktop-portal-termfilechooser
      ];
    };
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
