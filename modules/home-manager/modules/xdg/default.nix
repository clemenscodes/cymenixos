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
  desktop = "Desktop";
  documents = "Documents";
  downloads = "Downloads";
  music = "Music";
  pictures = "Pictures";
  public = "Public";
  videos = "Videos";
  wallpapers = pkgs.stdenv.mkDerivation {
    name = "wallpapers";
    src = pkgs.fetchFromGitHub {
      owner = "clemenscodes";
      repo = "walls";
      rev = "886dd0786cea003f9e94a1054137e7cbd8fd7428";
      hash = "sha256-GjP7ASUjfL9kqIx+/dhGkiBm1QmjwWn80bqhi3Vp6vM=";
    };
    installPhase = ''
      mkdir -p $out
      cp -r $src/* $out
      rm $out/README.md
    '';
  };
in {
  options = {
    modules = {
      xdg = {
        enable = lib.mkEnableOption "Enable XDG in home" // {default = false;};
      };
    };
  };
  config = lib.mkIf (osCfg.enable && cfg.enable && cfg.xdg.enable) {
    home = {
      persistence = {
        "${osConfig.modules.boot.impermanence.persistPath}${config.home.homeDirectory}" = {
          directories = [
            desktop
            documents
            downloads
            music
            pictures
            public
            videos
          ];
        };
      };
      file = {
        ".face" = {
          source = ./assets/face/.face;
        };
        "${config.xdg.userDirs.extraConfig.XDG_NOTE_DIR}/README.md" = {
          text = ''
            # Notes

            - where general notes are stored
            - run `notes` to cd into this directory
          '';
        };
        "${config.xdg.userDirs.extraConfig.XDG_SCREENSHOT_DIR}/README.md" = {
          text = ''
            # Screenshots

            - This is the directory where screenshots will be saved by swappy
            - run `sss to cd into this directory
          '';
        };
        "${config.xdg.userDirs.extraConfig.XDG_WALLPAPER_DIR}" = {
          source = "${wallpapers}";
          recursive = true;
        };
        "${config.xdg.userDirs.extraConfig.XDG_SVG_DIR}" = {
          source = ./assets/svg;
          recursive = true;
        };
        "${config.xdg.userDirs.extraConfig.XDG_ISO_DIR}/README.md" = {
          text = ''
            # Iso images

            - store iso images here
            - run `isos` to cd into this directory
          '';
        };
      };
    };
    xdg = {
      inherit (cfg.xdg) enable;
      userDirs = {
        enable = true;
        createDirectories = true;
        desktop = "${config.home.homeDirectory}/${desktop}";
        documents = "${config.home.homeDirectory}/${documents}";
        download = "${config.home.homeDirectory}/${downloads}";
        music = "${config.home.homeDirectory}/${music}";
        pictures = "${config.home.homeDirectory}/${pictures}";
        publicShare = "${config.home.homeDirectory}/${public}";
        videos = "${config.home.homeDirectory}/${videos}";
        templates = null;
        extraConfig = {
          XDG_BIN_HOME = "${config.home.homeDirectory}/.local/bin";
          XDG_SCREENSHOT_DIR = "${config.xdg.userDirs.pictures}/screenshots";
          XDG_WALLPAPER_DIR = "${config.xdg.userDirs.pictures}/wallpaper";
          XDG_SVG_DIR = "${config.xdg.userDirs.pictures}/svg";
          XDG_ISO_DIR = "${config.xdg.userDirs.publicShare}/isos";
          XDG_NOTE_DIR = "${config.xdg.userDirs.documents}/notes";
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
        "chars" = {
          source = ./assets/chars;
          recursive = true;
        };
        "fonts" = {
          source = ./assets/fonts;
          recursive = true;
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
