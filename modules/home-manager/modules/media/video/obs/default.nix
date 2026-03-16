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

  # Bitmask: enable first N audio tracks (1=0b1, 2=0b11, 3=0b111 … 6=0b111111)
  trackMask = builtins.foldl' (acc: _: acc * 2 + 1) 0 (lib.range 1 obsCfg.audio.tracks);

  # Files precomputed in the Nix store — copied to ~/.config/obs-studio on first run
  # (or on demand via obs-reset-config)
  websocketConfigFile = pkgs.writeText "obs-websocket-config.json" (builtins.toJSON {
    alerts_enabled = true;
    server_enabled = true;
    server_port = obsCfg.websocket.port;
    server_password = obsCfg.websocket.password;
  });

  recordEncoderFile = pkgs.writeText "obs-record-encoder.json" (builtins.toJSON {
    rate_control = "CQP";
    cqp = obsCfg.output.cqp;
  });

  streamEncoderFile = pkgs.writeText "obs-stream-encoder.json" (builtins.toJSON {
    rate_control = "CBR";
    bitrate = obsCfg.stream.bitrate;
  });

  # Minimal audio source entry (reused for desktop + mic global slots)
  mkAudioSource = name: uuid: pluginId: {
    prev_ver = 536870916;
    inherit name uuid;
    id = pluginId;
    versioned_id = pluginId;
    settings = {device_id = "default";};
    mixers = 255;
    sync = 0;
    flags = 0;
    volume = 1.0;
    balance = 0.5;
    enabled = true;
    muted = false;
    push-to-mute = false;
    push-to-mute-delay = 0;
    push-to-talk = false;
    push-to-talk-delay = 0;
    hotkeys = {
      "libobs.mute" = [];
      "libobs.unmute" = [];
      "libobs.push-to-mute" = [];
      "libobs.push-to-talk" = [];
    };
    deinterlace_mode = 0;
    deinterlace_field_order = 0;
    monitoring_type = 0;
    private_settings = {};
  };

  sceneCollectionFile = pkgs.writeText "obs-scene-collection.json" (builtins.toJSON {
    # Global audio devices
    DesktopAudioDevice1 = mkAudioSource "Desktop" "cyme0001-0001-0001-0001-000000000001" "pulse_output_capture";
    AuxAudioDevice1 = mkAudioSource "Mic" "cyme0001-0001-0001-0001-000000000002" "pulse_input_capture";

    current_scene = "Game";
    current_program_scene = "Game";
    scene_order = [{name = "Game";}];
    name = obsCfg.scenes.name;

    sources = [
      # Scene: "Game"
      {
        prev_ver = 536870916;
        name = "Game";
        uuid = "cyme0001-0001-0001-0001-000000000003";
        id = "scene";
        versioned_id = "scene";
        settings = {
          id_counter = 1;
          items = [
            {
              name = "VK Capture";
              source_uuid = "cyme0001-0001-0001-0001-000000000004";
              id = 1;
              pos = {x = 0.0; y = 0.0;};
              rot = 0.0;
              scale = {x = 1.0; y = 1.0;};
              align = 5;
              vis = true;
              muted = false;
              locked = false;
              crop_top = 0;
              crop_right = 0;
              crop_bottom = 0;
              crop_left = 0;
              crop_to_bounding_box = false;
              bounds_type = 2; # Scale to inner bounds
              bounds_align = 0;
              bounds = {x = obsCfg.profile.outputWidth * 1.0; y = obsCfg.profile.outputHeight * 1.0;};
              blend_method = 0;
              blend_type = 0;
              group_item_backup = false;
              scale_filter = 0;
              deinterlace_mode = 0;
              deinterlace_field_order = 0;
              show_transition = {};
              hide_transition = {};
            }
          ];
        };
        mixers = 0;
        sync = 0;
        flags = 0;
        volume = 1.0;
        balance = 0.5;
        enabled = true;
        muted = false;
        push-to-mute = false;
        push-to-mute-delay = 0;
        push-to-talk = false;
        push-to-talk-delay = 0;
        hotkeys = {};
        deinterlace_mode = 0;
        deinterlace_field_order = 0;
        monitoring_type = 0;
        private_settings = {};
      }
      # Source: VK Capture (linux-vkcapture, cursor disabled)
      {
        prev_ver = 536870916;
        name = "VK Capture";
        uuid = "cyme0001-0001-0001-0001-000000000004";
        id = "linux-vkcapture";
        versioned_id = "linux-vkcapture";
        settings = {show_cursor = false;};
        mixers = 0;
        sync = 0;
        flags = 0;
        volume = 1.0;
        balance = 0.5;
        enabled = true;
        muted = false;
        push-to-mute = false;
        push-to-mute-delay = 0;
        push-to-talk = false;
        push-to-talk-delay = 0;
        hotkeys = {};
        deinterlace_mode = 0;
        deinterlace_field_order = 0;
        monitoring_type = 0;
        private_settings = {};
      }
    ];

    quick_transitions = [
      {name = "Fade"; duration = 300; hotkeys = []; id = 1; is_default = false;}
      {name = "Cut"; duration = 0; hotkeys = []; id = 2; is_default = false;}
    ];
    transitions = [];
    saved_projectors = [];
    groups = [];
    modules = {};
    version = 2;
  });

  globalIniFile = pkgs.writeText "obs-global.ini" ''
    [General]
    EnableAutoUpdates=false
    ConfirmOnExit=false
    LastVersion=30000000
    CurrentProfile=${obsCfg.profile.name}

    [BasicWindow]
    RecordWhenStreaming=false
    KeepRecordingWhenStreamStops=false
    SysTrayEnabled=true
    SysTrayWhenStarted=true
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
    FPSInt=${toString obsCfg.profile.fpsNum}
    FPSDen=1
    BaseCX=${toString obsCfg.profile.baseWidth}
    BaseCY=${toString obsCfg.profile.baseHeight}
    OutputCX=${toString obsCfg.profile.outputWidth}
    OutputCY=${toString obsCfg.profile.outputHeight}
    ColorFormat=${obsCfg.profile.colorFormat}
    ColorDepth=10
    ColorSpace=${obsCfg.profile.colorSpace}
    ColorRange=Full
    SdrWhiteLevel=${toString obsCfg.profile.sdrWhiteLevel}
    HdrNominalPeakLevel=${toString obsCfg.profile.hdrNominalPeakLevel}
    ScaleType=bicubic

    [Output]
    Mode=Advanced
    FilenameFormatting=%CCYY-%MM-%DD %hh-%mm-%ss
    DelayEnable=false
    Reconnect=true
    RetryDelay=2
    MaxRetries=25
    IPFamily=IPv4+IPv6

    [AdvOut]
    RecFormat2=${obsCfg.output.format}
    RecFilePath=${obsCfg.output.path}
    RecEncoder=${obsCfg.output.encoder}
    RecAudioEncoder=${obsCfg.audio.encoder}
    RecTracks=${toString trackMask}
    Encoder=${obsCfg.stream.encoder}
    AudioEncoder=${obsCfg.stream.audioEncoder}
    RecType=Standard
    RecUseRescale=false
    RecSplitFileType=Time
    RecFileNameWithoutSpace=true
    Track1Bitrate=${toString obsCfg.audio.trackBitrate}
    Track2Bitrate=${toString obsCfg.audio.trackBitrate}
    Track3Bitrate=${toString obsCfg.audio.trackBitrate}
    Track4Bitrate=${toString obsCfg.audio.trackBitrate}
    Track5Bitrate=${toString obsCfg.audio.trackBitrate}
    Track6Bitrate=${toString obsCfg.audio.trackBitrate}
    Track1Name=Desktop
    Track2Name=Mic
    Track3Name=Browser
    Track4Name=Game
    Track5Name=AUX 1
    Track6Name=AUX 2
    RecRB=${lib.boolToString obsCfg.replayBuffer.enable}
    RecRBTime=${toString obsCfg.replayBuffer.seconds}
    RecRBSize=512

    [SimpleOutput]
    RecFormat2=${obsCfg.output.format}
    FilePath=${obsCfg.output.path}
    RecAudioEncoder=${obsCfg.audio.encoder}

    [ReplayBuffer]
    Duration=${toString obsCfg.replayBuffer.seconds}

    [Audio]
    SampleRate=48000
    ChannelSetup=Stereo

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

  # Launcher: force-sets the active profile in both config files before OBS reads them.
  # OBS 30+ stores the active profile in user.ini [Basic] Profile= / ProfileDir=.
  # OBS also overwrites global.ini on exit, so patching on every launch is the only reliable fix.
  obs-launch = pkgs.writeShellApplication {
    name = "obs-launch";
    runtimeInputs = [pkgs.gnused];
    text = ''
      OBS_DIR="$HOME/.config/obs-studio"
      PROFILE="${obsCfg.profile.name}"

      patch_ini_key() {
        local file="$1" section="$2" key="$3" value="$4"
        [[ -f "$file" ]] || return
        if grep -q "^$key=" "$file"; then
          sed -i "s|^$key=.*|$key=$value|" "$file"
        else
          sed -i "/^\[$section\]/a $key=$value" "$file"
        fi
      }

      # global.ini — legacy CurrentProfile key (OBS <30 / fallback)
      patch_ini_key "$OBS_DIR/global.ini"  "General" "CurrentProfile"        "$PROFILE"
      # user.ini — OBS 30+ active profile and scene collection keys
      patch_ini_key "$OBS_DIR/user.ini"    "Basic"   "Profile"               "$PROFILE"
      patch_ini_key "$OBS_DIR/user.ini"    "Basic"   "ProfileDir"            "$PROFILE"
      ${lib.optionalString obsCfg.scenes.enable ''
        patch_ini_key "$OBS_DIR/user.ini"  "Basic"   "SceneCollection"       "${obsCfg.scenes.name}"
        patch_ini_key "$OBS_DIR/user.ini"  "Basic"   "SceneCollectionFile"   "${obsCfg.scenes.name}.json"
      ''}

      exec obs --disable-shutdown-check ${lib.optionalString obsCfg.replayBuffer.enable "--startreplaybuffer"} "$@"
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

  # Deletes the seeded config files so the next nixos-rebuild re-applies Nix defaults.
  # Scenes and plugin configs are untouched.
  obs-reset-config = pkgs.writeShellApplication {
    name = "obs-reset-config";
    text = ''
      OBS_DIR="$HOME/.config/obs-studio"
      echo "Removing OBS seeded config files..."
      rm -f "$OBS_DIR/global.ini"
      rm -f "$OBS_DIR/plugin_config/obs-websocket/config.json"
      rm -f "$OBS_DIR/basic/profiles/${obsCfg.profile.name}/basic.ini"
      rm -f "$OBS_DIR/basic/profiles/${obsCfg.profile.name}/recordEncoder.json"
      rm -f "$OBS_DIR/basic/profiles/${obsCfg.profile.name}/streamEncoder.json"
      rm -f "$OBS_DIR/basic/scenes/${obsCfg.scenes.name}.json"
      echo "Done. Run 'sudo nixos-rebuild switch' to re-apply Nix defaults."
    '';
  };
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
                '';
              };
              colorSpace = lib.mkOption {
                type = lib.types.enum ["sRGB" "601" "709" "2100PQ" "2100HLG"];
                default = "709";
                description = "OBS color space. 2100PQ = HDR PQ (requires 10-bit colorFormat).";
              };
              sdrWhiteLevel = lib.mkOption {
                type = lib.types.int;
                default = 300;
                description = "SDR white level in nits (used when tonemapping HDR→SDR)";
              };
              hdrNominalPeakLevel = lib.mkOption {
                type = lib.types.int;
                default = 1000;
                description = "HDR nominal peak brightness in nits";
              };
            };

            audio = {
              encoder = lib.mkOption {
                type = lib.types.enum [
                  "ffmpeg_aac"
                  "ffmpeg_opus"
                  "ffmpeg_pcm_f32le"
                  "ffmpeg_pcm_s16le"
                  "libfdk_aac"
                  "ffmpeg_flac"
                ];
                default = "ffmpeg_aac";
                description = ''
                  Audio encoder for recording.
                  ffmpeg_pcm_f32le — 32-bit float PCM, uncompressed, universally compatible
                                     (use this for DaVinci Resolve — Opus breaks there).
                  ffmpeg_flac      — lossless compressed, ~50% smaller than PCM, also compatible.
                  ffmpeg_aac       — lossy AAC, smallest files, fine for streaming/delivery.
                  ffmpeg_opus      — better quality than AAC but breaks DaVinci Resolve.
                '';
              };
              tracks = lib.mkOption {
                type = lib.types.ints.between 1 6;
                default = 1;
                description = "Number of audio tracks to record (1–6). Enables the first N tracks.";
              };
              trackBitrate = lib.mkOption {
                type = lib.types.int;
                default = 320;
                description = "Per-track bitrate in kbps (only applies to lossy encoders like AAC/Opus; ignored for PCM/FLAC)";
              };
            };

            stream = {
              encoder = lib.mkOption {
                type = lib.types.enum [
                  "obs_nvenc_h264_tex"
                  "obs_nvenc_hevc_tex"
                  "obs_nvenc_av1_tex"
                  "ffmpeg_hevc_vaapi"
                  "obs_x264"
                ];
                default = "obs_nvenc_h264_tex";
                description = "Video encoder for streaming (lower latency than recording encoder).";
              };
              audioEncoder = lib.mkOption {
                type = lib.types.enum ["ffmpeg_aac" "ffmpeg_opus" "libfdk_aac"];
                default = "ffmpeg_aac";
                description = "Audio encoder for streaming.";
              };
              bitrate = lib.mkOption {
                type = lib.types.int;
                default = 6000;
                description = "Stream video bitrate in kbps (CBR).";
              };
            };

            output = {
              path = lib.mkOption {
                type = lib.types.str;
                default = "/home/${osConfig.modules.users.user}/Videos";
                description = "Recording output directory (absolute path — OBS %HOME expansion is unreliable on NixOS/Wayland).";
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
                  obs_nvenc_hevc_tex — NVENC HEVC, good HDR10 support, all NVENC hardware.
                '';
              };
              cqp = lib.mkOption {
                type = lib.types.ints.between 0 51;
                default = 20;
                description = ''
                  CQP quality level for NVENC recording (0 = best, 51 = worst).
                  20 is visually lossless for AV1/HEVC at 4K. Lower = larger files.
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

            scenes = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = ''
                  Seed a declarative scene collection on first run.
                  Contains a single "Game" scene with a VK Capture source (cursor disabled).
                  Seeded once — OBS can freely modify it afterward. Use obs-reset-config to re-seed.
                '';
              };
              name = lib.mkOption {
                type = lib.types.str;
                default = "Default";
                description = "Scene collection name (shown in OBS menu and used as the filename).";
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
        obs-launch
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
        obs-reset-config
      ];

      # global.ini is always overwritten — it controls which profile OBS opens,
      # and OBS rewrites it on every launch (so seed-if-absent would leave the
      # wrong profile selected after the first run).
      # Profile/encoder files use seed-if-absent so OBS can tune settings freely.
      # Run obs-reset-config to restore Nix defaults for those files.
      activation.obsInitConfig = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
        OBS_DIR="$HOME/.config/obs-studio"
        PROFILE_DIR="$OBS_DIR/basic/profiles/${obsCfg.profile.name}"
        WS_DIR="$OBS_DIR/plugin_config/obs-websocket"

        run mkdir -p "$PROFILE_DIR"
        run mkdir -p "$WS_DIR"
        run mkdir -p "$OBS_DIR/basic/scenes"

        seed() {
          local dest="$1" src="$2"
          if [[ ! -f "$dest" ]] || [[ -L "$dest" ]]; then
            run cp "$src" "$dest"
          fi
        }

        seed "$WS_DIR/config.json"             ${websocketConfigFile}
        run cp ${globalIniFile} "$OBS_DIR/global.ini"
        seed "$PROFILE_DIR/basic.ini"          ${profileIniFile}
        seed "$PROFILE_DIR/recordEncoder.json" ${recordEncoderFile}
        seed "$PROFILE_DIR/streamEncoder.json" ${streamEncoderFile}
        ${lib.optionalString obsCfg.scenes.enable ''
          seed "$OBS_DIR/basic/scenes/${obsCfg.scenes.name}.json" ${sceneCollectionFile}
        ''}
        run chmod 600 "$WS_DIR/config.json" 2>/dev/null || true
      '';
    };

    wayland.windowManager.hyprland = lib.mkIf (useHyprland && obsCfg.keybinds.enable) {
      settings = {
        bind = [
          "$mod, O, exec, obs-launch"
          "$mod CTRL, O, exec, obs-record-toggle"
          "$mod CTRL, T, exec, obs-stream-toggle"
          "$mod CTRL, B, exec, obs-replay-toggle"
          "$mod CTRL, S, exec, obs-replay-save"
          "$mod CTRL, V, exec, obs-vcam-toggle"
        ];
      };
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
        ];
      };
    };

  };
}
