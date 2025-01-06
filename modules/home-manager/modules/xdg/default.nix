{
  pkgs,
  lib,
  ...
}: {
  config,
  osConfig,
  ...
}: let
  cfg = config.modules;
  osCfg = osConfig.modules;
in {
  options = {
    modules = {
      xdg = {
        enable = lib.mkEnableOption "Enable XDG in home" // {default = false;};
      };
    };
  };
  config = lib.mkIf (osCfg.enable && cfg.enable && cfg.xdg.enable) {
    xdg = {
      inherit (cfg.xdg) enable;
      userDirs = {
        enable = true;
        createDirectories = true;
        extraConfig = {
          XDG_BIN_HOME = "${config.home.homeDirectory}/.local/bin";
        };
      };
      mimeApps = {
        enable = true;
      };
      portal = {
        enable = true;
        xdgOpenUsePortal = true;
        extraPortals = [pkgs.xdg-desktop-portal-gtk];
        config = {
          common = {
            default = "*";
          };
        };
      };
      dataFile = {
        "face" = {
          source = ./assets/face;
          recursive = true;
        };
        "chars" = {
          source = ./assets/chars;
          recursive = true;
        };
        "fonts" = {
          source = ./assets/fonts;
          recursive = true;
        };
        "images/wallpaper" = {
          source = ./assets/wallpaper;
          recursive = true;
        };
        "images/svg" = {
          source = ./assets/svg;
          recursive = true;
        };
        "notes/README.md" = {
          text = ''
            # Notes

            - where general notes are stored
            - run `notes` to cd into this directory
          '';
        };
        "images/screenshots/README.md" = {
          text = ''
            # Screenshots

            - This is the directory where screenshots will be saved by swappy
            - run `sss to cd into this directory
          '';
        };
        "nvim/undo/README.md" = {
          text = ''
            # Neovim undo direcotry

            - This is the directory where neovim stores its undo history
          '';
        };
        "isos/README.md" = {
          text = ''
            # Iso images

            - store iso images here
            - run `isos` to cd into this directory
          '';
        };
      };
      configFile = {
        nixpkgs = {
          text =
            /*
            nix
            */
            ''
              {
                packageOverrides = pkgs: {
                  nur =
                    import (builtins.fetchTarball {
                      url = "https://github.com/nix-community/NUR/archive/3a6a6f4da737da41e27922ce2cfacf68a109ebce.tar.gz";
                      sha256 = "04387gzgl8y555b3lkz9aiw9xsldfg4zmzp930m62qw8zbrvrshd";
                    }) {
                      inherit pkgs;
                    };
                };
              }
            '';
        };
      };
    };
  };
}
