{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: 
let cfg = config.modules.media;
inherit (osConfig.modules.users) user;
{
  imports = [
    (import ./dlplaylist {inherit inputs pkgs lib;})
    (import ./ncmpcpp {inherit inputs pkgs lib;})
    (import ./spotdl {inherit inputs pkgs lib;})
    (import ./spotify {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      media = {
        music = {
          enable = lib.mkEnableOption "Enable music" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.music.enable) {
    services = {
      mpd = {
        inherit (cfg.music) enable;
        musicDirectory = "${config.xdg.userDirs.music}";
        playlistDirectory = "${config.services.mpd.dataDir}/playlists";
        dataDir = "${config.xdg.configHome}/mpd";
        dbFile = "${config.services.mpd.dataDir}/tag_cache";
        extraConfig = ''
          user "${user}"

          audio_output {
            type "pulse"
            name "Pulse"
          }

          audio_output {
            type   "fifo"
            name   "fifo"
            path   "${config.services.mpd.dataDir}/fifo"
            format "44100:16:2"
          }

          audio_output {
            type "pipewire"
            name "PipeWire"
          }

          bind_to_address "/run/user/1000/mpd/socket"
          auto_update "yes"
          zeroconf_enabled "no"
        '';
        network = {
          startWhenNeeded = true;
        };
      };
    };
  }
}
