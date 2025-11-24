{
  pkgs,
  lib,
  ...
}: {
  config,
  osConfig,
  ...
}: let
  cfg = config.modules.media.video;
  isDesktop = osConfig.modules.display.gui != "headless";
  obs-cmd = pkgs.writeShellApplication {
    name = "obs-cmd";
    runtimeInputs = [
      pkgs.jq
      pkgs.obs-cmd
    ];
    text = ''
      CONFIG_PATH="$HOME/.config/obs-studio/plugin_config/obs-websocket/config.json"

      if [[ ! -f "$CONFIG_PATH" ]]; then
        echo "Error: OBS websocket config not found at $CONFIG_PATH" >&2
        exit 1
      fi

      OBS_WEBSOCKET_PORT="$(jq -r '.server_port // empty' "$CONFIG_PATH")"
      OBS_WEBSOCKET_PASSWORD="$(jq -r '.server_password // empty' "$CONFIG_PATH")"

      if [[ -z "$OBS_WEBSOCKET_PORT" || -z "$OBS_WEBSOCKET_PASSWORD" ]]; then
        echo "Error: Failed to extract port or password from OBS websocket config" >&2
        exit 1
      fi

      OBS_WEBSOCKET_URL="obsws://localhost:$OBS_WEBSOCKET_PORT/$OBS_WEBSOCKET_PASSWORD"
      export OBS_WEBSOCKET_URL

      exec obs-cmd "$@"
    '';
  };
in {
  options = {
    modules = {
      media = {
        video = {
          obs = {
            enable = lib.mkEnableOption "Enable OBS (open broadcast software)" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.obs.enable && isDesktop) {
    home = {
      persistence = lib.mkIf (osConfig.modules.boot.enable) {
        "${osConfig.modules.boot.impermanence.persistPath}${config.home.homeDirectory}" = {
          directories = [".config/obs-studio"];
        };
      };
      packages = [
        pkgs.gst_all_1.gstreamer
        pkgs.gst_all_1.gst-plugins-base
        pkgs.gst_all_1.gst-plugins-good
        pkgs.gst_all_1.gst-plugins-bad
        pkgs.gst_all_1.gst-plugins-ugly
        pkgs.gst_all_1.gst-libav
        pkgs.gst_all_1.gst-vaapi
        pkgs.nv-codec-headers-12
        obs-cmd
      ];
    };
    programs = {
      obs-studio = {
        inherit (cfg.obs) enable;
        package = pkgs.obs-studio.override {cudaSupport = true;};
        plugins = [
          pkgs.obs-studio-plugins.wlrobs
          pkgs.obs-studio-plugins.input-overlay
          pkgs.obs-studio-plugins.obs-pipewire-audio-capture
          pkgs.obs-studio-plugins.obs-vkcapture
          pkgs.obs-studio-plugins.obs-gstreamer
          pkgs.obs-studio-plugins.obs-vaapi
          pkgs.obs-studio-plugins.looking-glass-obs
        ];
      };
    };
  };
}
