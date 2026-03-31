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
      persistence = lib.mkIf osCfg.boot.enable {
        "${osConfig.modules.boot.impermanence.persistPath}" = {
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
      sessionVariables = {} // config.xdg.userDirs.extraConfig;
    };
    xdg = {
      inherit (cfg.xdg) enable;
      userDirs = {
        inherit (cfg.xdg) enable;
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
          XDG_DESKTOP_DIR = "${config.home.homeDirectory}/${desktop}";
          XDG_DOCUMENTS_DIR = "${config.home.homeDirectory}/${documents}";
          XDG_DOWNLOAD_DIR = "${config.home.homeDirectory}/${downloads}";
          XDG_MUSIC_DIR = "${config.home.homeDirectory}/${music}";
          XDG_PICTURES_DIR = "${config.home.homeDirectory}/${pictures}";
          XDG_PUBLIC_DIR = "${config.home.homeDirectory}/${public}";
          XDG_VIDEOS_DIR = "${config.home.homeDirectory}/${videos}";
          XDG_BIN_HOME = "${config.home.homeDirectory}/.local/bin";
          XDG_SCREENSHOT_DIR = "${config.xdg.userDirs.pictures}/screenshots";
          XDG_WALLPAPER_DIR = "${config.xdg.userDirs.pictures}/wallpaper";
          XDG_SVG_DIR = "${config.xdg.userDirs.pictures}/svg";
          XDG_ISO_DIR = "${config.xdg.userDirs.publicShare}/isos";
          XDG_NOTE_DIR = "${config.xdg.userDirs.documents}/notes";
        };
      };
      mimeApps = {
        inherit (cfg.xdg) enable;
        defaultApplications = {
          "application/x-pie-executable" = ["nvim.desktop"];
          "application/octet-stream" = ["nvim.desktop"];
          "application/x-object" = ["nvim.desktop"];
        };
      };
      portal = lib.mkIf (osConfig.modules.display.gui != "headless") {
        inherit (cfg.xdg) enable;
        xdgOpenUsePortal = true;
        extraPortals = [
          pkgs.xdg-desktop-portal
          pkgs.xdg-desktop-portal-gtk
          pkgs.xdg-desktop-portal-wlr
        ];
        config = {
          common = {
            default = "hyprland;gtk";
            "org.freedesktop.portal.OpenURI" = "gtk";
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
