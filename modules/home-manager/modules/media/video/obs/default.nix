{
  inputs,
  pkgs,
  lib,
  ...
}: {
  config,
  osConfig,
  ...
}: let
  cfg = config.modules.media.video;
  obsCfg = cfg.obs;
  isDesktop = osConfig.modules.display.gui != "headless";
  useHyprland = config.modules.display.compositor.hyprland.enable;
  isPersisted = osConfig.modules.boot.enable;
  persistPath = osConfig.modules.boot.impermanence.persistPath;

  websocketConfigFile = pkgs.writeText "obs-websocket-config.json" (builtins.toJSON {
    alerts_enabled = true;
    server_enabled = true;
    server_port = obsCfg.websocket.port;
    server_password = obsCfg.websocket.password;
  });

  globalIniFile = pkgs.writeText "obs-global.ini" ''
    [General]
    EnableAutoUpdates=false
    ConfirmOnExit=false
    LastVersion=30000000

    [BasicWindow]
    RecordWhenStreaming=false
    KeepRecordingWhenStreamStops=false
    SysTrayEnabled=false
    SysTrayWhenStarted=false
    SnappingEnabled=true
    SnapDistance=10
    OverflowHidden=false
    PreviewEnabled=true
  '';

  profileIniFile = pkgs.writeText "obs-profile-basic.ini" ''
    [General]
    Name=${obsCfg.profile.name}

    [Video]
    FPSType=1
    FPSNum=${toString obsCfg.profile.fpsNum}
    FPSDen=1
    BaseCX=${toString obsCfg.profile.baseWidth}
    BaseCY=${toString obsCfg.profile.baseHeight}
    OutputCX=${toString obsCfg.profile.outputWidth}
    OutputCY=${toString obsCfg.profile.outputHeight}
    ColorFormat=${obsCfg.profile.colorFormat}
    ColorDepth=10
    ColorSpace=${obsCfg.profile.colorSpace}
    ColorRange=Full

    [Output]
    Mode=Advanced

    [SimpleOutput]
    RecFormat2=${obsCfg.output.format}
    FilePath=${obsCfg.output.path}

    [AdvOut]
    RecFormat2=${obsCfg.output.format}
    RecFilePath=${obsCfg.output.path}
    RecEncoder=${obsCfg.output.encoder}
    RecTracks=1

    [ReplayBuffer]
    Duration=${toString obsCfg.replayBuffer.seconds}

    [Hotkeys]
    OBSBasic.StartRecording=[{"key":"OBS_KEY_O","modifiers":{"shift":false,"control":true,"alt":false,"command":true}}]
    OBSBasic.StopRecording=[{"key":"OBS_KEY_O","modifiers":{"shift":false,"control":true,"alt":false,"command":true}}]
    OBSBasic.StartStreaming=[{"key":"OBS_KEY_T","modifiers":{"shift":false,"control":true,"alt":false,"command":true}}]
    OBSBasic.StopStreaming=[{"key":"OBS_KEY_T","modifiers":{"shift":false,"control":true,"alt":false,"command":true}}]
    OBSBasic.StartReplayBuffer=[{"key":"OBS_KEY_B","modifiers":{"shift":false,"control":true,"alt":false,"command":true}}]
    OBSBasic.StopReplayBuffer=[{"key":"OBS_KEY_B","modifiers":{"shift":false,"control":true,"alt":false,"command":true}}]
    OBSBasic.ReplayBuffer.Save=[{"key":"OBS_KEY_S","modifiers":{"shift":false,"control":true,"alt":false,"command":true}}]
    OBSBasic.StartVirtualCam=[{"key":"OBS_KEY_V","modifiers":{"shift":false,"control":true,"alt":false,"command":true}}]
    OBSBasic.StopVirtualCam=[{"key":"OBS_KEY_V","modifiers":{"shift":false,"control":true,"alt":false,"command":true}}]
  '';

  mkObsScript = name: body:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [pkgs.jq pkgs.obs-cmd];
      text = ''
        CONFIG_PATH="$HOME/.config/obs-studio/plugin_config/obs-websocket/config.json"
        if [[ ! -f "$CONFIG_PATH" ]]; then
          echo "Error: OBS websocket config not found at $CONFIG_PATH" >&2
          exit 1
        fi
        OBS_WEBSOCKET_PORT="$(jq -r '.server_port // empty' "$CONFIG_PATH")"
        OBS_WEBSOCKET_PASSWORD="$(jq -r '.server_password // empty' "$CONFIG_PATH")"
        if [[ -z "$OBS_WEBSOCKET_PORT" || -z "$OBS_WEBSOCKET_PASSWORD" ]]; then
          echo "Error: Failed to read websocket config" >&2
          exit 1
        fi
        OBS_WEBSOCKET_URL="obsws://localhost:$OBS_WEBSOCKET_PORT/$OBS_WEBSOCKET_PASSWORD"
        export OBS_WEBSOCKET_URL
        ${body}
      '';
    };

  obs-cmd-wrapped = mkObsScript "obs-cmd" ''exec obs-cmd "$@"'';
  obs-record-toggle = mkObsScript "obs-record-toggle" "obs-cmd recording toggle";
  obs-stream-toggle = mkObsScript "obs-stream-toggle" "obs-cmd streaming toggle";
  obs-replay-save = mkObsScript "obs-replay-save" "obs-cmd replay-buffer save";
  obs-replay-toggle = mkObsScript "obs-replay-toggle" "obs-cmd replay-buffer toggle";
  obs-vcam-toggle = mkObsScript "obs-vcam-toggle" "obs-cmd virtual-cam toggle";
  obs-status = mkObsScript "obs-status" ''
    rec=$(obs-cmd recording status 2>/dev/null | jq -r '.outputActive // false')
    stream=$(obs-cmd streaming status 2>/dev/null | jq -r '.outputActive // false')
    replay=$(obs-cmd replay-buffer status 2>/dev/null | jq -r '.outputActive // false')
    vcam=$(obs-cmd virtual-cam status 2>/dev/null | jq -r '.outputActive // false')
    echo "rec=$rec stream=$stream replay=$replay vcam=$vcam"
  '';
in {
  options = {
    modules = {
      media = {
        video = {
          obs = {
            enable = lib.mkEnableOption "Enable OBS (open broadcast software)" // {default = false;};

            websocket = {
              port = lib.mkOption {
                type = lib.types.port;
                default = 4455;
                description = "OBS WebSocket server port (read by obs-cmd scripts)";
              };
              password = lib.mkOption {
                type = lib.types.str;
                default = "changeme";
                description = "OBS WebSocket password. Use SOPS for secrets management.";
              };
            };

            profile = {
              name = lib.mkOption {
                type = lib.types.str;
                default = "Default";
                description = "OBS profile name";
              };
              baseWidth = lib.mkOption {
                type = lib.types.int;
                default = 1920;
                description = "Canvas base width";
              };
              baseHeight = lib.mkOption {
                type = lib.types.int;
                default = 1080;
                description = "Canvas base height";
              };
              outputWidth = lib.mkOption {
                type = lib.types.int;
                default = 1920;
                description = "Output/render width";
              };
              outputHeight = lib.mkOption {
                type = lib.types.int;
                default = 1080;
                description = "Output/render height";
              };
              fpsNum = lib.mkOption {
                type = lib.types.int;
                default = 60;
                description = "Recording/streaming FPS";
              };
              colorFormat = lib.mkOption {
                type = lib.types.enum ["NV12" "I420" "I444" "P010" "I010" "BGRA"];
                default = "NV12";
                description = ''
                  OBS internal color format.
                  P010 = semi-planar 4:2:0 10-bit, NVENC native — use for HDR on NVIDIA.
                  NV12 = semi-planar 4:2:0 8-bit — safe default for SDR on any hardware.
                  I444 = 4:4:4 SDR only (HDR+4:4:4 unsupported in OBS).
                '';
              };
              colorSpace = lib.mkOption {
                type = lib.types.enum ["sRGB" "601" "709" "2100pq" "2100hlg"];
                default = "709";
                description = "OBS color space. 2100pq = HDR PQ, requires 10-bit colorFormat.";
              };
            };

            output = {
              path = lib.mkOption {
                type = lib.types.str;
                default = "%HOME/Videos/OBS";
                description = "Recording output directory";
              };
              format = lib.mkOption {
                type = lib.types.enum ["mkv" "mp4" "mov" "flv" "fragmented_mp4"];
                default = "mkv";
                description = "Recording container format. mkv is safest (no corruption on crash).";
              };
              encoder = lib.mkOption {
                type = lib.types.enum [
                  "obs_nvenc_hevc_tex"
                  "obs_nvenc_av1_tex"
                  "obs_nvenc_h264_tex"
                  "ffmpeg_hevc_vaapi"
                  "ffmpeg_av1_vaapi"
                  "obs_x264"
                  "ffmpeg_svt_av1"
                ];
                default = "obs_x264";
                description = ''
                  Video encoder for recording.
                  obs_x264          — software H.264, works on any hardware (safe default).
                  obs_nvenc_av1_tex — NVENC AV1, best quality/size, requires Ada Lovelace (RTX 40xx+).
                  obs_nvenc_hevc_tex — NVENC HEVC, good HDR10 support, works on all NVENC hardware.
                  ffmpeg_hevc_vaapi / ffmpeg_av1_vaapi — AMD/Intel hardware encode.
                '';
              };
            };

            replayBuffer = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Auto-start OBS with replay buffer enabled";
              };
              seconds = lib.mkOption {
                type = lib.types.int;
                default = 30;
                description = "Replay buffer duration in seconds";
              };
            };

            keybinds = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Register Hyprland keybinds for OBS control";
              };
            };
          };
        };
      };
    };
  };

  config = lib.mkIf (cfg.enable && obsCfg.enable && isDesktop) {
    home = {
      persistence = lib.mkIf isPersisted {
        "${persistPath}" = {
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
        obs-cmd-wrapped
        obs-record-toggle
        obs-stream-toggle
        obs-replay-save
        obs-replay-toggle
        obs-vcam-toggle
        obs-status
      ];

      activation.obsInitConfig = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
        OBS_DIR="$HOME/.config/obs-studio"
        PROFILE_DIR="$OBS_DIR/basic/profiles/${obsCfg.profile.name}"
        WS_DIR="$OBS_DIR/plugin_config/obs-websocket"

        run mkdir -p "$PROFILE_DIR"
        run mkdir -p "$WS_DIR"

        WS_CFG="$WS_DIR/config.json"
        if [[ ! -f "$WS_CFG" ]] || [[ -L "$WS_CFG" ]]; then
          run cp ${websocketConfigFile} "$WS_CFG"
          run chmod 600 "$WS_CFG"
        fi

        GLOBAL_INI="$OBS_DIR/global.ini"
        if [[ ! -f "$GLOBAL_INI" ]] || [[ -L "$GLOBAL_INI" ]]; then
          run cp ${globalIniFile} "$GLOBAL_INI"
        fi

        PROFILE_INI="$PROFILE_DIR/basic.ini"
        if [[ ! -f "$PROFILE_INI" ]] || [[ -L "$PROFILE_INI" ]]; then
          run cp ${profileIniFile} "$PROFILE_INI"
        fi
      '';
    };

    programs = {
      obs-studio = {
        inherit (obsCfg) enable;
        package = pkgs.obs-studio.override {cudaSupport = true;};
        plugins = [
          # === Capture ===
          pkgs.obs-studio-plugins.obs-vkcapture
          pkgs.obs-studio-plugins.wlrobs
          pkgs.obs-studio-plugins.looking-glass-obs
          pkgs.obs-studio-plugins.droidcam-obs

          # === Audio ===
          pkgs.obs-studio-plugins.obs-pipewire-audio-capture
          pkgs.obs-studio-plugins.waveform
          pkgs.obs-studio-plugins.obs-noise
          pkgs.obs-studio-plugins.obs-scale-to-sound

          # === Encoding & Output ===
          pkgs.obs-studio-plugins.obs-gstreamer
          pkgs.obs-studio-plugins.obs-vaapi
          pkgs.obs-studio-plugins.obs-multi-rtmp
          pkgs.obs-studio-plugins.obs-aitum-multistream
          pkgs.obs-studio-plugins.obs-source-record

          # === Network / Remote ===
          # distroav (NDI) excluded: requires unfree ndi-6 SDK — add manually if needed
          pkgs.obs-studio-plugins.obs-teleport

          # === Scene Management & Automation ===
          pkgs.obs-studio-plugins.advanced-scene-switcher
          pkgs.obs-studio-plugins.obs-move-transition
          pkgs.obs-studio-plugins.obs-transition-table
          pkgs.obs-studio-plugins.obs-scene-as-transition
          pkgs.obs-studio-plugins.obs-source-switcher
          pkgs.obs-studio-plugins.obs-source-clone

          # === Filters & Effects ===
          pkgs.obs-studio-plugins.obs-shaderfilter
          pkgs.obs-studio-plugins.obs-composite-blur
          pkgs.obs-studio-plugins.obs-backgroundremoval
          pkgs.obs-studio-plugins.obs-advanced-masks
          pkgs.obs-studio-plugins.obs-freeze-filter
          pkgs.obs-studio-plugins.obs-rgb-levels
          pkgs.obs-studio-plugins.obs-stroke-glow-shadow
          pkgs.obs-studio-plugins.obs-3d-effect
          # obs-color-monitor excluded: broken build in current nixpkgs (missing Qt target)
          pkgs.obs-studio-plugins.obs-retro-effects
          pkgs.obs-studio-plugins.obs-vintage-filter
          pkgs.obs-studio-plugins.obs-mute-filter

          # === Sources ===
          pkgs.obs-studio-plugins.obs-gradient-source
          pkgs.obs-studio-plugins.obs-replay-source
          pkgs.obs-studio-plugins.obs-text-pthread
          pkgs.obs-studio-plugins.obs-dir-watch-media
          pkgs.obs-studio-plugins.obs-media-controls

          # === Overlays & Info ===
          pkgs.obs-studio-plugins.input-overlay
          pkgs.obs-studio-plugins.obs-tuna
          pkgs.obs-studio-plugins.obs-plugin-countdown

          # === Vertical / Mobile ===
          pkgs.obs-studio-plugins.obs-vertical-canvas
        ];
      };
    };

    wayland.windowManager.hyprland = lib.mkIf useHyprland {
      settings = {
        bind = lib.optionals obsCfg.keybinds.enable [
          "$mod, O, exec, obs --disable-shutdown-check --multi${lib.optionalString obsCfg.replayBuffer.enable " --startreplaybuffer"}"
          "$mod CTRL, O, exec, obs-record-toggle"
          "$mod CTRL, T, exec, obs-stream-toggle"
          "$mod CTRL, B, exec, obs-replay-toggle"
          "$mod CTRL, S, exec, obs-replay-save"
          "$mod CTRL, V, exec, obs-vcam-toggle"
        ];
        windowrule = [
          "float on,  match:class ^(com\\.obsproject\\.Studio)$"
          "size 1400 900, match:class ^(com\\.obsproject\\.Studio)$"
          "center 1, match:class ^(com\\.obsproject\\.Studio)$"
          "fullscreen on, match:title ^(OBS.*(Fullscreen|Projector))$"
          "monitor 0,    match:title ^(OBS.*(Fullscreen|Projector))$"
        ];
      };
    };
  };
}
