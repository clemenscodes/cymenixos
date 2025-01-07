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
          {
            id = "ekhagklcjbdpajgpjgmbionohlpdbjgc"; # Zotero Connector
          }
        ];
      };
    };
  };
}
