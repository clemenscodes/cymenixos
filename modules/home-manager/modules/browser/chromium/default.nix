{
  pkgs,
  lib,
  ...
}: {
  osConfig,
  config,
  ...
}: let
  cfg = config.modules.browser;
in {
  options = {
    modules = {
      browser = {
        chromium = {
          enable = lib.mkEnableOption "Enable chromium" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.chromium.enable) {
    home = {
      persistence = {
        "${osConfig.modules.boot.impermanence.persistPath}${config.home.homeDirectory}" = {
          directories = [
            ".cache/BraveSoftware"
            ".config/BraveSoftware"
          ];
        };
      };
    };
    programs = {
      chromium = {
        inherit (cfg.chromium) enable;
        package = pkgs.brave;
        commandLineArgs = [
          "--enable-features=UseOzonePlatform"
          "--ozone-platform=wayland"
        ];
        dictionaries = [
          pkgs.hunspellDictsChromium.de_DE
          pkgs.hunspellDictsChromium.en_US
        ];
        extensions = [
          {
            id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; # ublock origin
          }
          {
            id = "nngceckbapebfimnlniiiahkandclblb"; # bitwarden
          }
          {
            id = "cmpdlhmnmjhihmcfnigoememnffkimlk"; # Catppuccin Chrome Theme - Macchiato
          }
          {
            id = "lnjaiaapbakfhlbjenjkhffcdpoompki"; # Catppuccin GitHub File Explorer Icons
          }
          {
            id = "hlepfoohegkhhmjieoechaddaejaokhf"; # Refined GitHub
          }
          {
            id = "kmhcihpebfmpgmihbkipmjlmmioameka"; # Eternl
          }
          {
            id = "dbepggeogbaibhgnhhndojpepiihcmeb"; # Vimium
          }
          {
            id = "khncfooichmfjbepaaaebmommgaepoid"; # Remove YouTube Shorts / Recommended
          }
          {
            id = "gebbhagfogifgggkldgodflihgfeippi"; # YouTube Dislikes
          }
        ];
      };
    };
    xdg = {
      mimeApps = {
        associations = {
          added = lib.mkIf (cfg.defaultBrowser == "brave") {
            "x-scheme-handler/http" = ["brave-browser.desktop"];
            "x-scheme-handler/https" = ["brave-browser.desktop"];
            "x-scheme-handler/chrome" = ["brave-browser.desktop"];
            "text/html" = ["brave-browser.desktop"];
            "application/x-extension-htm" = ["brave-browser.desktop"];
            "application/x-extension-html" = ["brave-browser.desktop"];
            "application/x-extension-shtml" = ["brave-browser.desktop"];
            "application/xhtml+xml" = ["brave-browser.desktop"];
            "application/x-extension-xhtml" = ["brave-browser.desktop"];
            "application/x-extension-xht" = ["brave-browser.desktop"];
          };
        };
        defaultApplications = lib.mkIf (cfg.defaultBrowser == "brave") {
          "x-scheme-handler/http" = ["brave-browser.desktop"];
          "x-scheme-handler/https" = ["brave-browser.desktop"];
          "x-scheme-handler/chrome" = ["brave-browser.desktop"];
          "text/html" = ["brave-browser.desktop"];
          "application/x-extension-htm" = ["brave-browser.desktop"];
          "application/x-extension-html" = ["brave-browser.desktop"];
          "application/x-extension-shtml" = ["brave-browser.desktop"];
          "application/xhtml+xml" = ["brave-browser.desktop"];
          "application/x-extension-xhtml" = ["brave-browser.desktop"];
          "application/x-extension-xht" = ["brave-browser.desktop"];
        };
      };
    };
  };
}
