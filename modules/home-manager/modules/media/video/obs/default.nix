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
  keyboardOverlayCfg = obsCfg.scenes.keyboardOverlay;
  isDesktop = osConfig.modules.display.gui != "headless";
  useHyprland = config.modules.display.compositor.hyprland.enable;
  isPersisted = osConfig.modules.boot.enable;
  persistPath = osConfig.modules.boot.impermanence.persistPath;

  # NV_ENC_SPLIT_ENCODE_MODE values as stored by obs-nvenc in "split_encode"
  splitEncodeModes = {
    auto = 0;
    two = 2;
    three = 3;
    four = 4;
    disabled = 15;
  };

  # Bitmask: enable first N audio tracks (1=0b1, 2=0b11, 3=0b111 … 6=0b111111)
  trackMask = builtins.foldl' (acc: _: acc * 2 + 1) 0 (lib.range 1 obsCfg.audio.tracks);

  # Bitmask of one track (track 1 → 1, track 2 → 2, track 3 → 4, …)
  singleTrackMixer = track: builtins.foldl' (acc: _: acc * 2) 1 (lib.range 1 (track - 1));
  # Bitmask of the tracks a source feeds
  tracksMixer = tracks: builtins.foldl' (acc: track: acc + singleTrackMixer track) 0 (lib.unique tracks);

  # Files precomputed in the Nix store — copied to ~/.config/obs-studio on first run
  # (or on demand via obs-reset-config)
  websocketConfigFile = pkgs.writeText "obs-websocket-config.json" (
    builtins.toJSON {
      # obs-websocket notifies every client connect and disconnect; obs-cmd (the OBS keybinds)
      # connects for each command, so every keypress left two desktop notifications.
      alerts_enabled = false;
      server_enabled = true;
      server_port = obsCfg.websocket.port;
      server_password = obsCfg.websocket.password;
    }
  );

  recordEncoderFile = pkgs.writeText "obs-record-encoder.json" (
    builtins.toJSON ({
      rate_control = "CQP";
      preset = obsCfg.output.preset;
      multipass = obsCfg.output.multipass;
      cqp = obsCfg.output.cqp;
      lookahead = obsCfg.output.lookahead;
      adaptive_quantization = obsCfg.output.adaptiveQuantization;
      bf = obsCfg.output.bFrames;
    }
    // lib.optionalAttrs (obsCfg.output.splitEncode != "auto") {
      split_encode = splitEncodeModes.${obsCfg.output.splitEncode};
    })
  );

  streamEncoderFile = pkgs.writeText "obs-stream-encoder.json" (
    builtins.toJSON {
      rate_control = "CBR";
      bitrate = obsCfg.stream.bitrate;
    }
  );

  scenesCfg = obsCfg.scenes;

  # A scene that records the microphone records it raw as well (audio.micRaw)
  rawMicSource = "Shure SM7B (raw)";
  withRawMic = items:
    items
    ++ lib.optional (obsCfg.audio.micRaw != null && builtins.any (item: item.source == "Shure SM7B") items) {
      source = rawMicSource;
      fit = "none";
      x = 0.0;
      y = 0.0;
      visible = true;
    };

  # Deterministic UUID-shaped id, so generated sources and scenes keep their identity across switches
  mkUuid = seed: let
    h = builtins.hashString "sha256" seed;
    part = start: len: builtins.substring start len h;
  in "${part 0 8}-${part 8 4}-${part 12 4}-${part 16 4}-${part 20 12}";

  mkSourceJson = name: src: {
    prev_ver = 536936448;
    inherit name;
    inherit (src) uuid settings volume filters;
    id = src.type;
    versioned_id = src.type;
    mixers = tracksMixer src.audioTracks;
    # OBS stores the sync offset in nanoseconds
    sync = src.syncOffset * 1000000;
    flags = 0;
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
  };

  mkSceneItemJson = index: item: let
    bw = obsCfg.profile.baseWidth * 1.0;
    bh = obsCfg.profile.baseHeight * 1.0;
    halfH = bh / 2.0;
    fill = item.fit == "canvas";
    # Items built in this module, outside the option type, carry no scale.
    scale = item.scale or 1.0;
  in {
    name = item.source;
    source_uuid = scenesCfg.sources.${item.source}.uuid;
    inherit (item) visible;
    locked = false;
    rot = 0.0;
    scale_ref = {
      x = bw;
      y = bh;
    };
    align = 5;
    bounds_type =
      if fill
      then 2
      else 0;
    bounds_align = 0;
    bounds_crop = false;
    crop_left = 0;
    crop_top = 0;
    crop_right = 0;
    crop_bottom = 0;
    id = index + 1;
    group_item_backup = false;
    pos = {
      inherit (item) x y;
    };
    pos_rel = {
      x = (item.x - bw / 2.0) / halfH;
      y = (item.y - bh / 2.0) / halfH;
    };
    scale = {
      x = scale;
      y = scale;
    };
    scale_rel = {
      x = scale;
      y = scale;
    };
    bounds =
      if fill
      then {
        x = bw;
        y = bh;
      }
      else {
        x = 0.0;
        y = 0.0;
      };
    bounds_rel =
      if fill
      then {
        x = bw / halfH;
        y = bh / halfH;
      }
      else {
        x = 0.0;
        y = 0.0;
      };
    scale_filter = "disable";
    blend_method = "default";
    blend_type = "normal";
    show_transition = {
      duration = 0;
    };
    hide_transition = {
      duration = 0;
    };
    private_settings = {};
  };

  orderedScenes = lib.sort (a: b: a.order < b.order || (a.order == b.order && a.name < b.name)) (
    lib.mapAttrsToList (name: scene: scene // {inherit name;}) scenesCfg.scenes
  );

  mkSceneJson = scene: let
    items = withRawMic scene.items;
  in {
    prev_ver = 536936448;
    inherit (scene) name uuid;
    id = "scene";
    versioned_id = "scene";
    settings = {
      id_counter = builtins.length items;
      custom_size = false;
      items = lib.imap0 mkSceneItemJson items;
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
    canvas_uuid = "6c69626f-6273-4c00-9d88-c5136d61696e";
    private_settings = {};
  };

  sourceType = lib.types.submodule ({name, ...}: {
    options = {
      type = lib.mkOption {
        type = lib.types.str;
        example = "kms-capture-source";
        description = "OBS source id (e.g. vkcapture-source, v4l2_input, pipewire_audio_input_capture, kms-capture-source).";
      };
      uuid = lib.mkOption {
        type = lib.types.str;
        default = mkUuid "source:${name}";
        defaultText = lib.literalMD "derived from the source name";
        description = "Source UUID. Keep it stable so OBS keeps per-source state across switches.";
      };
      settings = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = {};
        description = "Source settings as OBS stores them in the scene collection.";
      };
      audioTracks = lib.mkOption {
        type = lib.types.listOf (lib.types.ints.between 1 6);
        default = [];
        example = [1 2];
        description = "Recording tracks this audio source feeds. Empty for video-only sources.";
      };
      volume = lib.mkOption {
        type = lib.types.float;
        default = 1.0;
        description = "Linear volume multiplier (convert from dB with 10^(dB/20)).";
      };
      filters = lib.mkOption {
        type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
        default = [];
        description = "Filters as OBS stores them in the scene collection.";
      };
      syncOffset = lib.mkOption {
        type = lib.types.int;
        default = 0;
        example = 38;
        description = ''
          Sync offset of an audio source in milliseconds, as the advanced audio properties of OBS
          set it. A positive value delays the sound, e.g. the microphone by the latency of a
          webcam, so the voice meets the lips.
        '';
      };
    };
  });

  sceneItemType = lib.types.submodule {
    options = {
      source = lib.mkOption {
        type = lib.types.str;
        description = "Name of a source defined in scenes.sources.";
      };
      fit = lib.mkOption {
        type = lib.types.enum [
          "none"
          "canvas"
        ];
        default = "none";
        description = "canvas = scale to fit the whole canvas, none = native size at x/y.";
      };
      x = lib.mkOption {
        type = lib.types.float;
        default = 0.0;
        description = "Horizontal position of the top-left corner in canvas pixels.";
      };
      y = lib.mkOption {
        type = lib.types.float;
        default = 0.0;
        description = "Vertical position of the top-left corner in canvas pixels.";
      };
      visible = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether the item is visible.";
      };
      scale = lib.mkOption {
        type = lib.types.float;
        default = 1.0;
        description = "Scale of the item at native size (fit = none), such as 0.25 for a picture in the picture.";
      };
    };
  };

  sceneType = lib.types.submodule ({name, ...}: {
    options = {
      order = lib.mkOption {
        type = lib.types.int;
        default = 100;
        description = "Position in the scene list (ascending).";
      };
      uuid = lib.mkOption {
        type = lib.types.str;
        default = mkUuid "scene:${name}";
        defaultText = lib.literalMD "derived from the scene name";
        description = "Scene UUID.";
      };
      items = lib.mkOption {
        type = lib.types.listOf sceneItemType;
        default = [];
        description = "Scene items, bottom to top.";
      };
    };
  });

  sceneCollectionFile = pkgs.writeText "obs-scene-collection.json" (
    builtins.toJSON {
      name = obsCfg.scenes.name;
      sources = lib.mapAttrsToList mkSourceJson scenesCfg.sources ++ map mkSceneJson orderedScenes;
      groups = [];
      scene_order = map (scene: {inherit (scene) name;}) orderedScenes;
      current_scene = scenesCfg.current;
      current_program_scene = scenesCfg.current;
      canvases = [];
      current_transition = "Überblende";
      transition_duration = 300;
      transitions = [];
      quick_transitions = [];
      saved_projectors = [];
      preview_locked = false;
      scaling_enabled = false;
      scaling_level = -33;
      scaling_off_x = 0.0;
      scaling_off_y = 0.0;
      "virtual-camera" = {
        type2 = 3;
      };
      modules = {
        tuna = {
          vlc_prev_hotkey = [];
          vlc_next_hotkey = [];
        };
        "transition-table" = {
          transitions = [];
          enable_hotkey = [];
          disable_hotkey = [];
        };
        "advanced-scene-switcher" = {
          sceneGroups = [];
          macros = [];
          macroSettings = {
            highlightExecuted = false;
            highlightConditions = false;
            highlightActions = false;
            newMacroCheckInParallel = false;
            newMacroRegisterHotkey = false;
            newMacroUseShortCircuitEvaluation = false;
            saveSettingsOnMacroChange = true;
          };
          variables = [];
          switches = [];
          ignoreWindows = [];
          screenRegion = [];
          pauseEntries = [];
          sceneRoundTrip = [];
          sceneTransitions = [];
          defaultTransitions = [];
          defTransitionDelay = 0;
          ignoreIdleWindows = [];
          idleTargetType = 0;
          idleSceneName = "";
          idleTransitionName = "";
          idleEnable = false;
          idleTime = 60;
          executableSwitches = [];
          randomSwitches = [];
          fileSwitches = [];
          readEnabled = false;
          readPath = "";
          writeEnabled = false;
          writePath = "";
          mediaSwitches = [];
          timeSwitches = [];
          audioSwitches = [];
          audioFallbackTargetType = 0;
          audioFallbackScene = "";
          audioFallbackTransition = "";
          audioFallbackEnable = false;
          audioFallbackDuration = {
            value = {
              value = 0.0;
              type = 0;
            };
            unit = 0;
            version = 1;
          };
          videoSwitches = [];
          interval = 300;
          noMatchScene = {
            sceneSelection = {
              type = 0;
              name = "";
              canvasSelection = "Main";
            };
          };
          switch_if_not_matching = 0;
          noMatchDelay = {
            value = {
              value = 0.0;
              type = 0;
            };
            unit = 0;
            version = 1;
          };
          cooldown = {
            value = {
              value = 0.0;
              type = 0;
            };
            unit = 0;
            version = 1;
          };
          enableCooldown = false;
          active = true;
          startup_behavior = 0;
          autoStart = {
            event = 0;
            useAutoStartScene = false;
            sceneSelection = {
              type = 0;
              name = "";
              canvasSelection = "Main";
            };
            name = "";
            regexConfig = {
              enable = false;
              partial = false;
              options = 0;
            };
          };
          logLevel = 0;
          logLevelVersion = 1;
          showSystemTrayNotifications = false;
          disableHints = false;
          disableFilterComboboxFilter = false;
          warnPluginLoadFailure = true;
          hideLegacyTabs = true;
          priority0 = 10;
          priority1 = 0;
          priority2 = 2;
          priority3 = 8;
          priority4 = 6;
          priority5 = 9;
          priority6 = 7;
          priority7 = 4;
          priority8 = 1;
          priority9 = 5;
          priority10 = 3;
          threadPriority = 3;
          transitionOverrideOverride = false;
          adjustActiveTransitionType = true;
          lastImportPath = "";
          startHotkey = [];
          stopHotkey = [];
          toggleHotkey = [];
          newMacroHotkey = [
            {
              control = true;
              key = "OBS_KEY_N";
            }
          ];
          upMacroSegmentHotkey = [];
          downMacroSegmentHotkey = [];
          removeMacroSegmentHotkey = [];
          tabWidgetOrder = [
            {generalTab = 0;}
            {macroTab = 1;}
            {windowTitleTab = 2;}
            {executableTab = 3;}
            {screenRegionTab = 4;}
            {mediaTab = 5;}
            {fileTab = 6;}
            {randomTab = 7;}
            {timeTab = 8;}
            {idleTab = 9;}
            {sceneSequenceTab = 10;}
            {audioTab = 11;}
            {videoTab = 12;}
            {sceneGroupTab = 13;}
            {transitionsTab = 14;}
            {pauseTab = 15;}
            {websocketConnectionTab = 16;}
            {twitchConnectionTab = 17;}
            {variableTab = 18;}
            {actionQueueTab = 19;}
          ];
          saveWindowGeo = false;
          windowPosX = 0;
          windowPosY = 0;
          windowWidth = 0;
          windowHeight = 0;
          macroListMacroEditSplitterPosition = [];
          version = "GITDIR-NOTFOUND";
          macroSearchSettings = {
            showAlways = false;
            searchType = 0;
            searchString = "";
            regexConfig = {
              enable = false;
              partial = false;
              options = 0;
            };
          };
          tabSettings = {
            searchType = 0;
            searchString = "";
            regexConfig = {
              enable = false;
              partial = false;
              options = 0;
            };
          };
          dockSettings = {
            searchType = 0;
            searchString = "";
            regexConfig = {
              enable = false;
              partial = false;
              options = 0;
            };
          };
          addVariablesDock = false;
          websocketConnections = [];
          twitchConnections = [];
          actionQueues = [];
          dockWindows = {
            docks = [];
          };
          alwaysShowTabs = false;
        };
        "scripts-tool" = [];
        "output-timer" = {
          streamTimerHours = 0;
          streamTimerMinutes = 0;
          streamTimerSeconds = 0;
          recordTimerHours = 0;
          recordTimerMinutes = 0;
          recordTimerSeconds = 0;
          autoStartStreamTimer = false;
          autoStartRecordTimer = false;
          pauseRecordTimer = false;
        };
      };
      version = 2;
    }
  );

  globalIniFile = pkgs.writeText "obs-global.ini" ''
    [General]
    EnableAutoUpdates=false
    ConfirmOnExit=false
    LastVersion=99999999
    CurrentProfile=${obsCfg.profile.name}
    CurrentSceneCollection=${obsCfg.scenes.name}

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
    FilenameFormatting=${obsCfg.filenameFormatting}
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
    ${lib.concatStringsSep "\n" (lib.imap1 (index: name: "Track${toString index}Name=${name}") obsCfg.audio.trackNames)}
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
      runtimeInputs = [
        pkgs.jq
        pkgs.obs-cmd
        pkgs.gnugrep
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
          echo "Error: Failed to read websocket config" >&2
          exit 1
        fi
        OBS_WEBSOCKET_URL="obsws://localhost:$OBS_WEBSOCKET_PORT/$OBS_WEBSOCKET_PASSWORD"
        export OBS_WEBSOCKET_URL
        ${body}
      '';
    };

  # Launcher: passes --profile (and optionally --collection) directly so OBS
  # always opens the right profile regardless of user.ini state.
  obsArgs =
    [
      "--profile"
      obsCfg.profile.name
      "--multi"
      "--disable-missing-files-check"
      "--disable-updater"
    ]
    ++ lib.optional obsCfg.launch.minimized "--minimize-to-tray"
    ++ lib.optional obsCfg.launch.startReplayBuffer "--startreplaybuffer"
    ++ lib.optional obsCfg.launch.startRecording "--startrecording"
    ++ lib.optionals obsCfg.scenes.enable [
      "--collection"
      obsCfg.scenes.name
    ];

  obs-launch = pkgs.writeShellApplication {
    name = "obs-launch";
    text =
      lib.optionalString osConfig.modules.gpu.nvidia.enable ''
        # Force NVIDIA's EGL vendor so the portal/PipeWire DMA-buf path works.
        # Without this GLVND picks Mesa (sort_priority 50 > NVIDIA's 10), and Mesa
        # cannot import NVIDIA-allocated DMA-bufs → black screen in pipewire-desktop-capture-source.
        export __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json
        export LIBVA_DRIVER_NAME=nvidia
        export NVD_BACKEND=direct
      ''
      + "exec obs ${lib.escapeShellArgs obsArgs} \"$@\"";
  };

  obs-cmd-wrapped = mkObsScript "obs-cmd" ''exec obs-cmd "$@"'';
  obs-record-toggle = mkObsScript "obs-record-toggle" "obs-cmd recording toggle";
  obs-stream-toggle = mkObsScript "obs-stream-toggle" "obs-cmd streaming toggle";
  # obs-cmd prints text, not JSON: "recording status-active" exits 0 only while recording,
  # "streaming status" prints "Active: true|false", "replay status" prints
  # "Replay Buffer is (not) running". The replay buffer is "replay", the virtual camera
  # "virtual-camera" (which has no status).
  obs-replay-save = mkObsScript "obs-replay-save" "obs-cmd replay save";
  obs-replay-toggle = mkObsScript "obs-replay-toggle" "obs-cmd replay toggle";
  obs-vcam-toggle = mkObsScript "obs-vcam-toggle" "obs-cmd virtual-camera toggle";
  obs-status = mkObsScript "obs-status" ''
    rec=false
    if obs-cmd recording status-active >/dev/null 2>&1; then
      rec=true
    fi
    stream=false
    if obs-cmd streaming status 2>/dev/null | grep -q 'Active: true'; then
      stream=true
    fi
    replay=false
    if obs-cmd replay status 2>/dev/null | grep -q 'Replay Buffer is running'; then
      replay=true
    fi
    echo "rec=$rec stream=$stream replay=$replay"
  '';

  # obs-toggle: launch OBS if not running; gracefully stop it if it is.
  #
  # pgrep target: on NixOS the `obs` binary in PATH is a shell wrapper — the actual
  # running process is `.obs-wrapped`. pgrep -x obs never matches it; pgrep -x '.obs-wrapped' does.
  #
  # Shutdown order:
  #   1. stop replay buffer (flush buffered frames)
  #   2. stop recording (OBS muxes and seals the container)
  #   3. poll recording status up to 30 s until it is no longer active
  #   4. stop OBS with SIGINT and wait for it to exit (safe only after the file is sealed)
  # Graceful OBS shutdown. SIGINT makes OBS save everything and close its main window, the same
  # path as quitting from the GUI. SIGTERM only saves and quits the Qt loop, and a second signal
  # during that teardown can save a half torn down scene collection. Only `.obs-wrapped` is
  # signalled: a pattern like `pkill obs` also hits obs-cmd and these scripts themselves.
  stopObsFunction = ''
    stop_obs() {
      local pid
      pid="$(pgrep -x '.obs-wrapped' | head -n 1)" || return 0
      [ -n "$pid" ] || return 0
      kill -INT "$pid" 2>/dev/null || return 0
      if ! timeout 30 tail --pid="$pid" -f /dev/null; then
        echo "OBS did not exit within 30 s; leaving it running" >&2
        return 1
      fi
    }
  '';

  obs-toggle = pkgs.writeShellApplication {
    name = "obs-toggle";
    runtimeInputs = [pkgs.jq pkgs.obs-cmd pkgs.procps pkgs.coreutils];
    text = ''
      ${stopObsFunction}
      if pgrep -x '.obs-wrapped' > /dev/null 2>&1; then
        CONFIG_PATH="$HOME/.config/obs-studio/plugin_config/obs-websocket/config.json"
        if [[ -f "$CONFIG_PATH" ]]; then
          OBS_WEBSOCKET_PORT="$(jq -r '.server_port // empty' "$CONFIG_PATH")"
          OBS_WEBSOCKET_PASSWORD="$(jq -r '.server_password // empty' "$CONFIG_PATH")"
          if [[ -n "$OBS_WEBSOCKET_PORT" && -n "$OBS_WEBSOCKET_PASSWORD" ]]; then
            export OBS_WEBSOCKET_URL="obsws://localhost:$OBS_WEBSOCKET_PORT/$OBS_WEBSOCKET_PASSWORD"
            obs-cmd replay stop 2>/dev/null || true
            obs-cmd recording stop 2>/dev/null || true
            remaining=30
            while [ "$remaining" -gt 0 ]; do
              if ! obs-cmd recording status-active >/dev/null 2>&1; then
                break
              fi
              sleep 1
              remaining=$((remaining - 1))
            done
          fi
        fi
        stop_obs
      else
        exec ${obs-launch}/bin/obs-launch
      fi
    '';
  };

  # obs-proxy: creates Proxy/<name>.mov for every recording in the output folder that has
  # none. It never encodes while OBS does (recording or replay buffer): the recording uses
  # every NVENC engine, so a proxy job beside it would cost frames. When OBS starts encoding
  # during a job, the job is stopped, its partial file removed, and the recording is picked
  # up again on the next run.
  proxyCfg = obsCfg.output.proxy;
  proxyWidth = obsCfg.profile.outputWidth * proxyCfg.height / obsCfg.profile.outputHeight;
  proxyColorArgs =
    {
      "2100PQ" = "-color_primaries bt2020 -color_trc smpte2084 -colorspace bt2020nc";
      "2100HLG" = "-color_primaries bt2020 -color_trc arib-std-b67 -colorspace bt2020nc";
      "709" = "-color_primaries bt709 -color_trc bt709 -colorspace bt709";
    }
    .${
      obsCfg.profile.colorSpace
    }
    or "";
  obs-proxy = pkgs.writeShellApplication {
    name = "obs-proxy";
    runtimeInputs = [pkgs.jq pkgs.obs-cmd pkgs.procps pkgs.coreutils pkgs.util-linux pkgs.ffmpeg-full];
    text = ''
      recordings=${lib.escapeShellArg obsCfg.output.path}
      proxies="$recordings/Proxy"
      config="$HOME/.config/obs-studio/plugin_config/obs-websocket/config.json"

      # True while OBS records or keeps its replay buffer, and while OBS runs but cannot be
      # asked (unknown counts as encoding).
      obs_encodes() {
        if ! pgrep -x '.obs-wrapped' >/dev/null; then
          return 1
        fi
        if [ ! -f "$config" ]; then
          return 0
        fi
        OBS_WEBSOCKET_URL="obsws://localhost:$(jq -r '.server_port' "$config")/$(jq -r '.server_password' "$config")"
        export OBS_WEBSOCKET_URL
        # obs-cmd prints text: "Active: true|false" and "Replay Buffer is (not) running"
        local recording replay
        if ! recording=$(obs-cmd recording status); then
          return 0
        fi
        if ! replay=$(obs-cmd replay status); then
          return 0
        fi
        [[ "$recording" != *"Active: false"* || "$replay" != *"Replay Buffer is not running"* ]]
      }

      # Encodes the proxy of $master into $part: decoded and scaled on the GPU, or with
      # "cpu" scaled on the CPU, for what NVDEC or scale_cuda cannot take (H.264 4:4:4,
      # 8 bit 4:4:4 HEVC to 10 bit). Returns the status of ffmpeg; ends the script when
      # OBS starts encoding meanwhile.
      encode() {
        local pipeline job
        if [ "$1" = gpu ]; then
          pipeline=(-hwaccel cuda -hwaccel_output_format cuda -i "$master" -vf scale_cuda=${toString proxyWidth}:${toString proxyCfg.height}:format=p010le)
        else
          pipeline=(-hwaccel cuda -i "$master" -vf "scale=${toString proxyWidth}:${toString proxyCfg.height}:flags=bicubic,format=p010le")
        fi
        # shellcheck disable=SC2086
        ffmpeg -nostdin -hide_banner -loglevel error -y "''${pipeline[@]}" \
          -map 0:v:0 -map '0:a?' \
          -c:v hevc_nvenc -preset p4 -rc vbr -cq 23 -b:v 0 -maxrate 60M -bufsize 120M -profile:v main10 \
          ${proxyColorArgs} \
          -c:a pcm_s24le "$part" &
        job=$!
        while kill -0 "$job" 2>/dev/null; do
          if obs_encodes; then
            kill "$job"
            wait "$job" || true
            rm -f "$part"
            echo "OBS started encoding, proxy of $name postponed"
            exit 0
          fi
          sleep 5
        done
        wait "$job"
      }

      mkdir -p "$proxies"
      exec 9>"$proxies/.lock"
      if ! flock -n 9; then
        exit 0
      fi

      # Newest first: OBS names recordings by date and time, so the name order is the
      # time order, and the recordings edited next are the latest ones
      shopt -s nullglob
      masters=("$recordings"/*.${obsCfg.output.format})
      for ((index = ''${#masters[@]} - 1; index >= 0; index--)); do
        master=''${masters[index]}
        name=$(basename "$master" .${obsCfg.output.format})
        proxy="$proxies/$name.mov"
        if [ -e "$proxy" ]; then
          continue
        fi
        # A master no larger than a proxy and in 4:2:0 already plays easily
        height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "$master" | head -n 1)
        pixel_format=$(ffprobe -v error -select_streams v:0 -show_entries stream=pix_fmt -of default=noprint_wrappers=1:nokey=1 "$master" | head -n 1)
        if [ "$height" -le ${toString proxyCfg.height} ] && [[ "$pixel_format" != *444* && "$pixel_format" != *422* ]]; then
          continue
        fi
        if obs_encodes; then
          echo "OBS is encoding, proxies wait"
          exit 0
        fi
        part="$proxies/.$name.part.mov"
        if encode gpu || encode cpu; then
          mv "$part" "$proxy"
          echo "proxy $proxy"
        else
          rm -f "$part"
          echo "proxy of $name failed" >&2
        fi
      done
    '';
  };

  # obs-ensure-open: Idempotently bring OBS to the running+recording state.
  #
  # Owns OBS state only — callers are responsible for any other side effects.
  #
  # State machine:
  #   OBS not running        → exec obs-launch (args include --startrecording --startreplaybuffer)
  #   OBS running, not rec   → start recording; ensure replay buffer also running
  #   OBS running, recording → ensure replay buffer running; otherwise no-op
  obs-ensure-open = pkgs.writeShellApplication {
    name = "obs-ensure-open";
    runtimeInputs = [pkgs.jq pkgs.obs-cmd pkgs.procps pkgs.gnugrep];
    text = ''
      CONFIG_PATH="$HOME/.config/obs-studio/plugin_config/obs-websocket/config.json"

      if pgrep -x '.obs-wrapped' > /dev/null 2>&1; then
        if [[ -f "$CONFIG_PATH" ]]; then
          OBS_WEBSOCKET_PORT="$(jq -r '.server_port // empty' "$CONFIG_PATH")"
          OBS_WEBSOCKET_PASSWORD="$(jq -r '.server_password // empty' "$CONFIG_PATH")"
          if [[ -n "$OBS_WEBSOCKET_PORT" && -n "$OBS_WEBSOCKET_PASSWORD" ]]; then
            export OBS_WEBSOCKET_URL="obsws://localhost:$OBS_WEBSOCKET_PORT/$OBS_WEBSOCKET_PASSWORD"
            if ! obs-cmd recording status-active >/dev/null 2>&1; then
              obs-cmd recording start 2>/dev/null || true
            fi
            if ! obs-cmd replay status 2>/dev/null | grep -q 'Replay Buffer is running'; then
              obs-cmd replay start 2>/dev/null || true
            fi
          fi
        fi
      else
        exec ${obs-launch}/bin/obs-launch --startrecording --startreplaybuffer
      fi
    '';
  };

  # obs-ensure-closed: Idempotently bring OBS to the stopped state.
  #
  # Owns OBS state only — callers are responsible for any other side effects.
  #
  # State machine:
  #   OBS running     → graceful shutdown (stop replay → stop recording → wait → pkill)
  #   OBS not running → no-op
  obs-ensure-closed = pkgs.writeShellApplication {
    name = "obs-ensure-closed";
    runtimeInputs = [pkgs.jq pkgs.obs-cmd pkgs.procps pkgs.coreutils];
    text = ''
      ${stopObsFunction}
      CONFIG_PATH="$HOME/.config/obs-studio/plugin_config/obs-websocket/config.json"

      if pgrep -x '.obs-wrapped' > /dev/null 2>&1; then
        if [[ -f "$CONFIG_PATH" ]]; then
          OBS_WEBSOCKET_PORT="$(jq -r '.server_port // empty' "$CONFIG_PATH")"
          OBS_WEBSOCKET_PASSWORD="$(jq -r '.server_password // empty' "$CONFIG_PATH")"
          if [[ -n "$OBS_WEBSOCKET_PORT" && -n "$OBS_WEBSOCKET_PASSWORD" ]]; then
            export OBS_WEBSOCKET_URL="obsws://localhost:$OBS_WEBSOCKET_PORT/$OBS_WEBSOCKET_PASSWORD"
            obs-cmd replay stop 2>/dev/null || true
            obs-cmd recording stop 2>/dev/null || true
            remaining=30
            while [ "$remaining" -gt 0 ]; do
              if ! obs-cmd recording status-active >/dev/null 2>&1; then
                break
              fi
              sleep 1
              remaining=$((remaining - 1))
            done
          fi
        fi
        stop_obs
        ${lib.optionalString proxyCfg.enable ''
        # OBS no longer encodes: the recordings of this session get their proxies now
        ${pkgs.systemd}/bin/systemctl --user start --no-block obs-proxy.service
      ''}
      fi
    '';
  };

  # Deletes the seeded config files so the next nixos-rebuild re-applies Nix defaults.
  # global.ini is not seeded (OBS manages it), so it is not removed here.
  obs-reset-config = pkgs.writeShellApplication {
    name = "obs-reset-config";
    text = ''
      OBS_DIR="$HOME/.config/obs-studio"
      echo "Removing OBS seeded config files..."
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
            enable =
              lib.mkEnableOption "Enable OBS (open broadcast software)"
              // {
                default = false;
              };
            package = lib.mkOption {
              type = lib.types.package;
              default = pkgs.obs-studio.override {cudaSupport = true;};
              defaultText = lib.literalExpression "pkgs.obs-studio.override {cudaSupport = true;}";
              description = "OBS package, e.g. with machine-specific patches applied via overrideAttrs.";
            };
            resetOnSwitch = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Overwrite the seeded OBS config (profile, encoders, websocket, scene collection) on every
                home-manager activation. The files stay regular and writable, so OBS can still change them
                at runtime for tweaking; the next switch restores the declared state.
                When false, they are only written if missing (first run or after obs-reset-config).
              '';
            };
            launch = {
              minimized = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Start OBS minimized to the tray (obs-launch, obs-toggle, SUPER + O).";
              };
              startRecording = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Start recording when OBS is launched. obs-ensure-open always starts recording.";
              };
              startReplayBuffer = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Start the replay buffer when OBS is launched. obs-ensure-open always starts it.";
              };
            };
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
              passwordFile = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = ''
                  A file whose content is the OBS WebSocket password, such as a SOPS secret owned by
                  the user. The activation writes it into the websocket config in place of
                  `password`, so the password never lands in the Nix store.
                '';
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
                type = lib.types.enum [
                  "NV12"
                  "I420"
                  "I444"
                  "P010"
                  "I010"
                  "P416"
                  "BGRA"
                ];
                default = "NV12";
                description = ''
                  OBS internal color format.
                  P010 = semi-planar 4:2:0 10-bit, NVENC native — use for HDR on NVIDIA.
                  NV12 = semi-planar 4:2:0 8-bit — safe default for SDR on any hardware.
                  P416 = 4:4:4 16-bit planes, for 4:4:4 HDR (Rec.2100). Stock obs-nvenc rejects it;
                         it needs a patched OBS package (see the package option).
                '';
              };
              colorSpace = lib.mkOption {
                type = lib.types.enum [
                  "sRGB"
                  "601"
                  "709"
                  "2100PQ"
                  "2100HLG"
                ];
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
              trackNames = lib.mkOption {
                type = lib.types.addCheck (lib.types.listOf lib.types.str) (names: builtins.length names == 6);
                default = ["Desktop" "Mic" "Browser" "Game" "AUX 1" "AUX 2"];
                description = ''
                  Names of the six recording tracks. OBS writes them into the recording as the
                  track titles, which is what an editor such as DaVinci Resolve shows.
                '';
              };
              trackBitrate = lib.mkOption {
                type = lib.types.int;
                default = 320;
                description = "Per-track bitrate in kbps (only applies to lossy encoders like AAC/Opus; ignored for PCM/FLAC)";
              };
              mic = lib.mkOption {
                type = lib.types.str;
                default = "default";
                description = ''
                  PipeWire/PulseAudio source name for the microphone input in OBS.
                  Use "default" for the system default input, or set to a specific
                  PipeWire node name (e.g. "SM7B_Processed" for a filter-chain virtual source).
                '';
              };
              gameSource = lib.mkOption {
                type = lib.types.str;
                default = "SDL Application";
                description = ''
                  PipeWire application name to capture as game audio.
                  Shown in the OBS "Game Sound" source (application_audio_output_capture).
                  Common values: "SDL Application" (most games), or the specific process name.
                '';
              };
              gameSourceExcept = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [];
                example = ["Brave" "Firefox" "Discord"];
                description = ''
                  When not empty, GameSound captures every application except these
                  (matched by PipeWire application name) instead of the single gameSource.
                  Games name their streams after themselves (cs2, CrimsonDesert.exe, …), so
                  a list of what is not a game catches every game, including new ones,
                  without routing game audio through an extra sink and its latency.
                '';
              };
              gameSourceVolume = lib.mkOption {
                type = lib.types.float;
                default = 0.178;
                description = ''
                  OBS linear volume multiplier (0.0–1.0) for the GameSound source.
                  OBS stores volume as a linear amplitude value; convert from dB with 10^(dB/20).

                  OBS meter ranges (for reference):
                    Red    :   0 to  -9 dB  (clip danger)
                    Yellow :  -9 to -20 dB
                    Green  : -20 to -60 dB  (upper green ≈ -24 to -30 dB)

                  Common dB → linear conversions:
                      0 dB → 1.0     (default, maximum)
                    -20 dB → 0.1
                    -30 dB → 0.0316
                    -35 dB → 0.0178
                    -38 dB → 0.0126  (good starting point for game audio behind voice)
                    -40 dB → 0.01
                    -50 dB → 0.00316
                '';
              };
              gameSourceTracks = lib.mkOption {
                type = lib.types.listOf (lib.types.ints.between 1 6);
                default = [1];
                description = ''
                  OBS recording tracks the GameSound source feeds (1–6). One track of its own
                  per source keeps clean stems; a shared mix track may be added.
                '';
              };
              micTracks = lib.mkOption {
                type = lib.types.listOf (lib.types.ints.between 1 6);
                default = [2];
                description = "OBS recording tracks the microphone (Shure SM7B) source feeds (1–6).";
              };
              desktopAudioTracks = lib.mkOption {
                type = lib.types.listOf (lib.types.ints.between 1 6);
                default = [3];
                description = ''
                  OBS recording tracks the DesktopAudio source (pipewire_audio_output_capture)
                  feeds (1–6). Keeping it apart from the game tracks avoids collisions when
                  switching between the Game and Work scenes mid-recording.
                '';
              };
              micRaw = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                example = "alsa_input.usb-Focusrite_Scarlett_2i2_4th_Gen_S2AJV133401118-00.HiFi__Mic1__source";
                description = ''
                  PipeWire node of the unprocessed microphone input. When set, every scene with
                  the microphone also records it raw on micRawTracks, so the voice can be
                  processed again in post without what the live chain baked in.
                '';
              };
              micRawTracks = lib.mkOption {
                type = lib.types.listOf (lib.types.ints.between 1 6);
                default = [];
                description = "OBS recording tracks the raw microphone source feeds (1–6).";
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
                type = lib.types.enum [
                  "ffmpeg_aac"
                  "ffmpeg_opus"
                  "libfdk_aac"
                ];
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
              proxy = {
                enable = lib.mkEnableOption ''
                  a proxy for every recording, in Proxy/<name>.mov beside it. DaVinci Resolve
                  links such a proxy on import and edits with it, while it renders from the
                  recording. A 4K 4:4:4 240 fps master decodes slower than real time even on
                  NVDEC; the proxy (1080p, H.265 4:2:0 10 bit) plays easily
                '';
                height = lib.mkOption {
                  type = lib.types.int;
                  default = 1080;
                  description = "Height of the proxies; the width follows the output aspect ratio.";
                };
              };
              format = lib.mkOption {
                type = lib.types.enum [
                  "mkv"
                  "mp4"
                  "mov"
                  "flv"
                  "fragmented_mp4"
                ];
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
              preset = lib.mkOption {
                type = lib.types.enum [
                  "p1"
                  "p2"
                  "p3"
                  "p4"
                  "p5"
                  "p6"
                  "p7"
                ];
                default = "p4";
                description = ''
                  NVENC encoder preset (p1 = fastest/lowest quality, p7 = slowest/best quality).
                  p2 = low-latency, p4 = balanced, p7 = highest quality.
                '';
              };
              multipass = lib.mkOption {
                type = lib.types.enum [
                  "disabled"
                  "qres"
                  "fullres"
                ];
                default = "fullres";
                description = ''
                  NVENC multipass encoding mode.
                  fullres = best quality (two passes at full resolution).
                  qres    = faster (first pass at quarter resolution).
                  disabled = single pass.
                '';
              };
              lookahead = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Enable NVENC lookahead for better rate control.";
              };
              adaptiveQuantization = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Enable NVENC adaptive quantization (improves perceptual quality).";
              };
              bFrames = lib.mkOption {
                type = lib.types.ints.between 0 4;
                default = 0;
                description = "Number of B-frames. 0 disables B-frames (required for some encoders like AV1).";
              };
              splitEncode = lib.mkOption {
                type = lib.types.enum [
                  "auto"
                  "disabled"
                  "two"
                  "three"
                  "four"
                ];
                default = "auto";
                description = ''
                  NVENC split frame encoding (HEVC and AV1 only): split each frame across several
                  NVENC engines for more throughput, e.g. 4K at high frame rates.
                  auto = driver decides (OBS default), two/three/four = forced number of strips,
                  only effective when the GPU has that many engines.
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
            scripts = {
              obs-ensure-open = lib.mkOption {
                type = lib.types.package;
                readOnly = true;
                description = "obs-ensure-open script derivation.";
              };
              obs-ensure-closed = lib.mkOption {
                type = lib.types.package;
                readOnly = true;
                description = "obs-ensure-closed script derivation.";
              };
            };
            filenameFormatting = lib.mkOption {
              type = lib.types.str;
              default = "%CCYY-%MM-%DD_%hh-%mm-%ss";
              description = "The recorded filename format";
            };
            scenes = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = ''
                  Seed a declarative scene collection on first run.
                  Contains two scenes:
                    "Game" — VK Capture (cursor off) + GameSound + Shure SM7B
                    "Work" — Screen (pipewire-desktop-capture-source) + DesktopAudio + Shure SM7B
                  Screen uses the PipeWire/portal path (hardware DMA-buf, zero-copy). On NVIDIA,
                  obs-launch forces __EGL_VENDOR_LIBRARY_FILENAMES=10_nvidia.json so the DMA-buf
                  import succeeds (Mesa EGL cannot import NVIDIA DMA-bufs, causing a black screen).
                  On first launch OBS shows the portal picker; the RestoreToken is written back and
                  persisted via impermanence so no re-selection is needed after reboot.
                  Seeded once — OBS can freely modify it afterward. Use obs-reset-config to re-seed.
                '';
              };
              name = lib.mkOption {
                type = lib.types.str;
                default = "Default";
                description = "Scene collection name (shown in OBS menu and used as the filename).";
              };
              sources = lib.mkOption {
                type = lib.types.attrsOf sourceType;
                default = {};
                description = ''
                  Sources of the scene collection, keyed by source name. The module defines the built-in
                  sources (VK Capture, GameSound, Shure SM7B, Keyboard Overlay, Screen, DesktopAudio) with
                  overridable defaults; add machine-specific sources here.
                '';
              };
              scenes = lib.mkOption {
                type = lib.types.attrsOf sceneType;
                default = {};
                description = ''
                  Scenes of the collection, keyed by scene name. The built-in "Game" and "Work" scenes have
                  overridable default items; set items to replace them or add new scenes.
                '';
              };
              current = lib.mkOption {
                type = lib.types.str;
                default = "Game";
                description = "Scene that is active when OBS starts.";
              };
              screenCapture = {
                output = lib.mkOption {
                  type = lib.types.str;
                  default = "";
                  description = ''
                    Unused. Kept for backwards compatibility; the Screen source now uses
                    pipewire-desktop-capture-source (xdg-desktop-portal) which selects the
                    capture target via the portal picker, not an output name.
                  '';
                };
              };
              keyboardOverlay = {
                enable =
                  lib.mkEnableOption "keyboard overlay browser source in the Game scene"
                  // {
                    default = false;
                  };
                url = lib.mkOption {
                  type = lib.types.str;
                  default = "http://localhost:7331";
                  description = "URL for the keyboard overlay browser source (e.g. evglow endpoint).";
                };
                width = lib.mkOption {
                  type = lib.types.int;
                  default = 1280;
                  description = "Width of the browser source in pixels.";
                };
                height = lib.mkOption {
                  type = lib.types.int;
                  default = 400;
                  description = "Height of the browser source in pixels.";
                };
                fps = lib.mkOption {
                  type = lib.types.int;
                  default = 60;
                  description = "Browser source framerate.";
                };
                pos = {
                  x = lib.mkOption {
                    type = lib.types.float;
                    default = 0.0;
                    description = "Horizontal position of the overlay top-left corner in the scene canvas (pixels from left). Uses OBS Top-Left anchor (align=5).";
                  };
                  y = lib.mkOption {
                    type = lib.types.float;
                    default = 0.0;
                    description = "Vertical position of the overlay top-left corner in the scene canvas (pixels from top). Uses OBS Top-Left anchor (align=5).";
                  };
                };
                extraCss = lib.mkOption {
                  type = lib.types.str;
                  default = "";
                  description = "Custom CSS injected into the browser source.";
                  example = "body { background: transparent !important; }";
                };
              };
            };
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && obsCfg.enable && isDesktop) {
    modules.media.video.obs.scripts = {inherit obs-ensure-open obs-ensure-closed;};

    modules.media.video.obs.scenes = {
      sources =
        {
          "VK Capture" = {
            type = lib.mkDefault "vkcapture-source";
            uuid = lib.mkDefault "cyme0001-0001-0001-0001-000000000004";
            settings = lib.mkDefault {show_cursor = false;};
          };
          GameSound = {
            type = lib.mkDefault "pipewire_audio_application_capture";
            uuid = lib.mkDefault "b84d7fe9-1968-45f5-864d-d656d56b019b";
            # obs-pipewire-audio-capture: CaptureMode 1 captures several applications,
            # ExceptApp inverts the list, MatchPriorty (sic) 1 matches the application
            # name before the binary
            settings = lib.mkDefault (
              if obsCfg.audio.gameSourceExcept == []
              then {TargetName = obsCfg.audio.gameSource;}
              else {
                CaptureMode = 1;
                ExceptApp = true;
                MatchPriorty = 1;
                apps =
                  map (app: {
                    value = app;
                    selected = false;
                    hidden = false;
                  })
                  obsCfg.audio.gameSourceExcept;
              }
            );
            audioTracks = lib.mkDefault obsCfg.audio.gameSourceTracks;
            volume = lib.mkDefault obsCfg.audio.gameSourceVolume;
          };
          # No filter: the microphone arrives processed (e.g. SM7B_Processed, limited at
          # -1.5 dBFS), and a second processing stage in OBS would be baked into the take.
          "Shure SM7B" = {
            type = lib.mkDefault "pipewire_audio_input_capture";
            uuid = lib.mkDefault "9e0dd964-6f7e-4aca-9f09-f118d39826ab";
            settings = lib.mkDefault {
              TargetId = 43;
              TargetName = obsCfg.audio.mic;
            };
            audioTracks = lib.mkDefault obsCfg.audio.micTracks;
          };
          # PipeWire/portal capture (hardware DMA-buf). On NVIDIA, obs-launch forces NVIDIA's EGL vendor.
          # The portal RestoreToken is written back by OBS; resetOnSwitch clears it again.
          Screen = {
            type = lib.mkDefault "pipewire-desktop-capture-source";
            uuid = lib.mkDefault "cyme0001-0001-0001-0001-000000000006";
            settings = lib.mkDefault {
              ShowCursor = true;
              RestoreToken = "";
            };
          };
          DesktopAudio = {
            type = lib.mkDefault "pipewire_audio_output_capture";
            uuid = lib.mkDefault "cyme0001-0001-0001-0001-000000000008";
            audioTracks = lib.mkDefault obsCfg.audio.desktopAudioTracks;
          };
        }
        // lib.optionalAttrs (obsCfg.audio.micRaw != null) {
          ${rawMicSource} = {
            type = lib.mkDefault "pipewire_audio_input_capture";
            settings = lib.mkDefault {TargetName = obsCfg.audio.micRaw;};
            audioTracks = lib.mkDefault obsCfg.audio.micRawTracks;
          };
        }
        // lib.optionalAttrs keyboardOverlayCfg.enable {
          "Keyboard Overlay" = {
            type = lib.mkDefault "browser_source";
            uuid = lib.mkDefault "cyme0001-0001-0001-0001-000000000005";
            settings = lib.mkDefault {
              url = keyboardOverlayCfg.url;
              width = keyboardOverlayCfg.width;
              height = keyboardOverlayCfg.height;
              fps = keyboardOverlayCfg.fps;
              css = keyboardOverlayCfg.extraCss;
              shutdown = false;
              restart_when_active = false;
            };
          };
        };
      scenes = {
        Game = {
          order = lib.mkDefault 10;
          uuid = lib.mkDefault "cyme0001-0001-0001-0001-000000000003";
          items = lib.mkDefault (
            [
              {
                source = "VK Capture";
                fit = "canvas";
              }
              {source = "GameSound";}
              {source = "Shure SM7B";}
            ]
            ++ lib.optional keyboardOverlayCfg.enable {
              source = "Keyboard Overlay";
              fit = "canvas";
              inherit (keyboardOverlayCfg.pos) x y;
            }
          );
        };
        Work = {
          order = lib.mkDefault 20;
          uuid = lib.mkDefault "cyme0001-0001-0001-0001-000000000007";
          items = lib.mkDefault [
            {
              source = "Screen";
              fit = "canvas";
            }
            {source = "DesktopAudio";}
            {source = "Shure SM7B";}
          ];
        };
      };
    };

    # Proxies run when a recording lands in the output folder, every 10 minutes for the
    # recordings that had to wait for OBS, and after obs-ensure-closed.
    systemd.user = lib.mkIf proxyCfg.enable {
      services.obs-proxy = {
        Unit.Description = "Proxies for OBS recordings";
        Service = {
          Type = "oneshot";
          ExecStart = "${obs-proxy}/bin/obs-proxy";
          Nice = 19;
          IOSchedulingClass = "idle";
        };
      };
      paths.obs-proxy = {
        Unit.Description = "New OBS recordings";
        Path.PathChanged = obsCfg.output.path;
        Install.WantedBy = ["default.target"];
      };
      timers.obs-proxy = {
        Unit.Description = "Proxies for OBS recordings that waited";
        Timer = {
          OnBootSec = "5min";
          OnUnitActiveSec = "10min";
        };
        Install.WantedBy = ["timers.target"];
      };
    };

    home = {
      persistence = lib.mkIf isPersisted {
        "${persistPath}" = {
          directories = [
            ".config/obs-studio"
            # The xdg-desktop-portal permission store lives here. Persisting it
            # means the screencast restore token (seeded by obsInitConfig) survives
            # reboots even before the next home-manager activation has run.
            ".local/share/flatpak/db"
          ];
        };
      };
      packages =
        [
          obs-launch
          pkgs.gst_all_1.gstreamer
          pkgs.gst_all_1.gst-plugins-base
          pkgs.gst_all_1.gst-plugins-good
          pkgs.gst_all_1.gst-plugins-bad
          pkgs.gst_all_1.gst-plugins-ugly
          pkgs.gst_all_1.gst-libav
          pkgs.nv-codec-headers-12
          obs-toggle
          obs-ensure-open
          obs-ensure-closed
          obs-cmd-wrapped
          obs-record-toggle
          obs-stream-toggle
          obs-replay-save
          obs-replay-toggle
          obs-vcam-toggle
          obs-status
          obs-reset-config
        ]
        ++ lib.optional proxyCfg.enable obs-proxy;

      # All config files use seed-if-absent so OBS can freely update them at runtime.
      # global.ini is intentionally NOT seeded: OBS creates it on first run with the
      # correct LastVersion, avoiding "unable to migrate global configuration" errors.
      # The --profile/--collection flags in obs-launch ensure the right profile and
      # scene collection are always loaded regardless of global.ini state.
      # Run obs-reset-config to restore Nix defaults for all seeded files.
      activation.obsInitConfig = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
        OBS_DIR="$HOME/.config/obs-studio"
        PROFILE_DIR="$OBS_DIR/basic/profiles/${obsCfg.profile.name}"
        WS_DIR="$OBS_DIR/plugin_config/obs-websocket"

        run mkdir -p "$PROFILE_DIR"
        run mkdir -p "$WS_DIR"
        run mkdir -p "$OBS_DIR/basic/scenes"
        run mkdir -p "${obsCfg.output.path}"

        seed() {
          local dest="$1" src="$2"
          if ${lib.boolToString obsCfg.resetOnSwitch} || [[ ! -f "$dest" ]] || [[ -L "$dest" ]]; then
            run install -m 644 "$src" "$dest"
          fi
        }

        seed "$WS_DIR/config.json"             ${websocketConfigFile}
        seed "$PROFILE_DIR/basic.ini"          ${profileIniFile}
        seed "$PROFILE_DIR/recordEncoder.json" ${recordEncoderFile}
        seed "$PROFILE_DIR/streamEncoder.json" ${streamEncoderFile}
        ${lib.optionalString obsCfg.scenes.enable ''
          seed "$OBS_DIR/basic/scenes/${obsCfg.scenes.name}.json" ${sceneCollectionFile}
        ''}
        ${lib.optionalString (obsCfg.websocket.passwordFile != null) ''
          # The password comes from its file, never from the store.
          if [[ -r ${obsCfg.websocket.passwordFile} ]]; then
            websocket_config="$(mktemp)"
            ${pkgs.jq}/bin/jq --rawfile password ${obsCfg.websocket.passwordFile} \
              '.server_password = ($password | rtrimstr("\n"))' "$WS_DIR/config.json" > "$websocket_config"
            run install -m 600 "$websocket_config" "$WS_DIR/config.json"
            rm -f "$websocket_config"
          else
            echo "obs: ${obsCfg.websocket.passwordFile} cannot be read, so obs-websocket keeps its password" >&2
          fi
        ''}
        run chmod 600 "$WS_DIR/config.json" 2>/dev/null || true
      '';
    };

    wayland.windowManager.hyprland = lib.mkIf (useHyprland && obsCfg.keybinds.enable) {
      extraConfig = ''
        hl.bind("SUPER + O",      hl.dsp.exec_cmd("${obs-toggle}/bin/obs-toggle"))
        hl.bind("SUPER + CTRL + O", hl.dsp.exec_cmd("obs-record-toggle"))
        hl.bind("SUPER + CTRL + T", hl.dsp.exec_cmd("obs-stream-toggle"))
        hl.bind("SUPER + CTRL + B", hl.dsp.exec_cmd("obs-replay-toggle"))
        hl.bind("SUPER + CTRL + S", hl.dsp.exec_cmd("obs-replay-save"))
        hl.bind("SUPER + CTRL + V", hl.dsp.exec_cmd("obs-vcam-toggle"))
      '';
    };

    programs = {
      obs-studio = {
        inherit (obsCfg) enable;
        inherit (obsCfg) package;
        plugins = [
          # === Capture ===
          pkgs.obs-studio-plugins.obs-vkcapture
          # wlrobs uses zwlr_screencopy_manager_v1 directly (bypasses xdph portal)
          # The portal path is stuck at BGRA 8-bit; direct screencopy may give proper HDR format
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

    # Override the OBS desktop entry so app launchers (anyrun, rofi, etc.)
    # all go through obs-toggle: opens OBS if closed, gracefully stops it if running.
    xdg.desktopEntries."com.obsproject.Studio" = {
      name = "OBS Studio";
      genericName = "Streaming/Recording Software";
      comment = "Free and Open Source Streaming/Recording Software";
      exec = "${obs-toggle}/bin/obs-toggle";
      icon = "com.obsproject.Studio";
      terminal = false;
      type = "Application";
      categories = [
        "AudioVideo"
        "Recorder"
      ];
      startupNotify = true;
    };
  };
}
