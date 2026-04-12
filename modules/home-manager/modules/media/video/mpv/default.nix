{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.media.video;
in {
  options = {
    modules = {
      media = {
        video = {
          mpv = {
            enable = lib.mkEnableOption "Enable mpv" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.mpv.enable) {
    programs = {
      mpv = {
        inherit (cfg.mpv) enable;
        package = pkgs.mpv.override {scripts = [pkgs.mpvScripts.mpris];};
        bindings = {
          l = "seek 5";
          h = "seek -5";
          j = "seek -60";
          k = "seek 60";
          S = "cycle sub";
        };
      };
    };
    xdg.configFile."mpv/scripts/merge-audio-tracks.lua".text = ''
      -- Dynamically merge all audio tracks via amix so multi-track files
      -- (e.g. OBS recordings with isolated stems) play as a single mix.
      -- Single-track files are left untouched.
      local function merge_audio()
        local tracks = mp.get_property_native("track-list")
        local n = 0
        for _, t in ipairs(tracks) do
          if t.type == "audio" then n = n + 1 end
        end
        if n <= 1 then return end
        local inputs = ""
        for i = 1, n do
          inputs = inputs .. "[aid" .. i .. "]"
        end
        mp.set_property("lavfi-complex", inputs .. "amix=inputs=" .. n .. ":normalize=0[ao]")
      end
      mp.register_event("file-loaded", merge_audio)
    '';

    xdg.mimeApps = {
      defaultApplications = let
        videoTypes = [
          "video/mp4"
          "video/x-matroska"
          "video/webm"
          "video/x-msvideo"
          "video/vnd.avi"
          "video/quicktime"
          "video/mpeg"
          "video/ogg"
          "video/3gpp"
          "video/3gpp2"
          "video/x-flv"
          "video/x-wmv"
          "video/x-ms-wmv"
          "video/x-ogm+ogg"
          "video/x-theora+ogg"
          "video/x-mkv"
        ];
      in
        builtins.listToAttrs (map (mime: {
            name = mime;
            value = ["mpv.desktop"];
          })
          videoTypes);
      associations.removed = let
        videoTypes = [
          "video/mp4"
          "video/x-matroska"
          "video/webm"
          "video/x-msvideo"
          "video/vnd.avi"
          "video/quicktime"
          "video/mpeg"
          "video/ogg"
          "video/3gpp"
          "video/3gpp2"
          "video/x-flv"
          "video/x-wmv"
          "video/x-ms-wmv"
          "video/x-ogm+ogg"
          "video/x-theora+ogg"
          "video/x-mkv"
        ];
        # umpv is a companion script shipped with mpv that reuses a running instance;
        # it registers its own desktop entry but we never want it as a default.
        unwanted = ["umpv.desktop" "brave-browser.desktop" "vlc.desktop"];
      in
        builtins.listToAttrs (map (mime: {
            name = mime;
            value = unwanted;
          })
          videoTypes);
    };
  };
}
