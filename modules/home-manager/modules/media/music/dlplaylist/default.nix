{
  pkgs,
  lib,
  ...
}: {
  config,
  osConfig,
  ...
}: let
  dlplaylist = pkgs.writeShellScriptBin "dlplaylist" ''
    dest=${
      if osConfig.modules.wsl.enable
      then "$WINMUSIC"
      else "$XDG_MUSIC_DIR"
    }
    ${pkgs.yt-dlp}/bin/yt-dlp  --yes-playlist -o "$dest/%(title)s.%(ext)s" -f 'bestaudio/best' --extract-audio --audio-format opus --cookies-from-browser ${config.modules.browser.defaultBrowser} "$@"
  '';
  cfg = config.modules.media.music;
in {
  options = {
    modules = {
      media = {
        music = {
          dlplaylist = {
            enable = lib.mkEnableOption "Enable dlplaylist script to download youtube playlists" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.dlplaylist.enable) {
    home = {
      packages = [dlplaylist];
    };
  };
}
