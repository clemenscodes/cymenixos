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
    preset = obsCfg.output.preset;
    multipass = obsCfg.output.multipass;
    cqp = obsCfg.output.cqp;
    lookahead = obsCfg.output.lookahead;
    adaptive_quantization = obsCfg.output.adaptiveQuantization;
    bf = obsCfg.output.bFrames;
  });

  streamEncoderFile = pkgs.writeText "obs-stream-encoder.json" (builtins.toJSON {
    rate_control = "CBR";
    bitrate = obsCfg.stream.bitrate;
  });

  # PipeWire application audio output capture (game sound, SDL, etc.)
  mkPipeWireAppSource = name: uuid: targetName: {
    prev_ver = 536936448;
    inherit name uuid;
    id = "pipewire_audio_application_capture";
    versioned_id = "pipewire_audio_application_capture";
    settings = {TargetName = targetName;};
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

  # PipeWire audio input source with filters (for scene sources like SM7B)
  mkPipeWireSource = name: uuid: targetName: filters: {
    prev_ver = 536936448;
    inherit name uuid filters;
    id = "pipewire_audio_input_capture";
    versioned_id = "pipewire_audio_input_capture";
    settings = {TargetName = targetName; TargetId = 0;};
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

  mkFilter = name: uuid: id: settings: {
    prev_ver = 536936448;
    inherit name uuid id settings;
    versioned_id = id;
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
    hotkeys = {};
    deinterlace_mode = 0;
    deinterlace_field_order = 0;
    monitoring_type = 0;
    private_settings = {};
  };

  sm7bFilters = [
    (mkFilter "RNNoise"    "37f2a665-504b-45a8-a991-4661e445fc59" "noise_suppress_filter_v2" {})
    (mkFilter "Speex"      "0dc549b9-2c50-44e0-afec-6b84b763ca35" "noise_suppress_filter_v2" {suppress_level = -15; method = "speex";})
    (mkFilter "Kompressor" "d6b36017-e914-44cc-b947-03b1f87219c5" "compressor_filter"        {ratio = 4.0;})
    (mkFilter "Limiter"    "f98982cf-dd71-4a24-ac47-f1d5a3b13760" "limiter_filter"           {threshold = -2.0;})
  ];

  # Minimal audio source entry (reused for desktop + mic global slots)
  mkAudioSource = name: uuid: pluginId: deviceId: {
    prev_ver = 536936448;
    inherit name uuid;
    id = pluginId;
    versioned_id = pluginId;
    settings = {device_id = deviceId;};
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
    name = obsCfg.scenes.name;
    DesktopAudioDevice1 = mkAudioSource "Desktop" "cyme0001-0001-0001-0001-000000000001" "pulse_output_capture" "default";
    AuxAudioDevice1     = mkAudioSource "Mic"     "cyme0001-0001-0001-0001-000000000002" "pulse_input_capture" obsCfg.audio.mic;

    sources = [
      # 1. VK Capture
      {
        prev_ver = 536936448;
        name = "VK Capture";
        uuid = "cyme0001-0001-0001-0001-000000000004";
        id = "vkcapture-source";
        versioned_id = "vkcapture-source";
        settings = {show_cursor = false;};
        mixers = 0; sync = 0; flags = 0; volume = 1.0; balance = 0.5;
        enabled = true; muted = false;
        push-to-mute = false; push-to-mute-delay = 0;
        push-to-talk = false; push-to-talk-delay = 0;
        hotkeys = {};
        deinterlace_mode = 0; deinterlace_field_order = 0; monitoring_type = 0;
        private_settings = {};
      }
      # 2. GameSound (SDL Application via PipeWire app capture)
      (mkPipeWireAppSource "GameSound" "b84d7fe9-1968-45f5-864d-d656d56b019b" obsCfg.audio.gameSource)
      # 3. Shure SM7B (PipeWire input with broadcast filter chain)
      ((mkPipeWireSource "Shure SM7B" "9e0dd964-6f7e-4aca-9f09-f118d39826ab" obsCfg.audio.mic sm7bFilters) // {
        settings = {TargetId = 43; TargetName = obsCfg.audio.mic;};
      })
      # 4. Game scene — contains VK Capture (video) + GameSound + SM7B (audio)
      {
        prev_ver = 536936448;
        name = "Game";
        uuid = "cyme0001-0001-0001-0001-000000000003";
        id = "scene";
        versioned_id = "scene";
        settings = {
          id_counter = 3;
          custom_size = false;
          items = [
            {
              name = "VK Capture";
              source_uuid = "cyme0001-0001-0001-0001-000000000004";
              visible = true; locked = false; rot = 0.0;
              scale_ref = {x = 3840.0; y = 2160.0;};
              align = 5; bounds_type = 2; bounds_align = 0; bounds_crop = false;
              crop_left = 0; crop_top = 0; crop_right = 0; crop_bottom = 0;
              id = 1; group_item_backup = false;
              pos = {x = 0.0; y = 0.0;};
              pos_rel = {x = -1.7777777910232544; y = -1.0;};
              scale = {x = 1.0; y = 1.0;};
              scale_rel = {x = 1.0; y = 1.0;};
              bounds = {x = 3840.0; y = 2160.0;};
              bounds_rel = {x = 3.555555582046509; y = 2.0;};
              scale_filter = "disable"; blend_method = "default"; blend_type = "normal";
              show_transition = {duration = 0;}; hide_transition = {duration = 0;};
              private_settings = {};
            }
            {
              name = "GameSound";
              source_uuid = "b84d7fe9-1968-45f5-864d-d656d56b019b";
              visible = true; locked = false; rot = 0.0;
              scale_ref = {x = 3840.0; y = 2160.0;};
              align = 5; bounds_type = 0; bounds_align = 0; bounds_crop = false;
              crop_left = 0; crop_top = 0; crop_right = 0; crop_bottom = 0;
              id = 2; group_item_backup = false;
              pos = {x = 0.0; y = 0.0;};
              pos_rel = {x = -1.7777777910232544; y = -1.0;};
              scale = {x = 1.0; y = 1.0;};
              scale_rel = {x = 1.0; y = 1.0;};
              bounds = {x = 0.0; y = 0.0;};
              bounds_rel = {x = 0.0; y = 0.0;};
              scale_filter = "disable"; blend_method = "default"; blend_type = "normal";
              show_transition = {duration = 300;}; hide_transition = {duration = 300;};
              private_settings = {};
            }
            {
              name = "Shure SM7B";
              source_uuid = "9e0dd964-6f7e-4aca-9f09-f118d39826ab";
              visible = true; locked = false; rot = 0.0;
              scale_ref = {x = 3840.0; y = 2160.0;};
              align = 5; bounds_type = 0; bounds_align = 0; bounds_crop = false;
              crop_left = 0; crop_top = 0; crop_right = 0; crop_bottom = 0;
              id = 3; group_item_backup = false;
              pos = {x = 0.0; y = 0.0;};
              pos_rel = {x = -1.7777777910232544; y = -1.0;};
              scale = {x = 1.0; y = 1.0;};
              scale_rel = {x = 1.0; y = 1.0;};
              bounds = {x = 0.0; y = 0.0;};
              bounds_rel = {x = 0.0; y = 0.0;};
              scale_filter = "disable"; blend_method = "default"; blend_type = "normal";
              show_transition = {duration = 300;}; hide_transition = {duration = 300;};
              private_settings = {};
            }
          ];
        };
        mixers = 0; sync = 0; flags = 0; volume = 1.0; balance = 0.5;
        enabled = true; muted = false;
        push-to-mute = false; push-to-mute-delay = 0;
        push-to-talk = false; push-to-talk-delay = 0;
        hotkeys = {
          "OBSBasic.SelectScene" = [];
          "libobs.show_scene_item.1" = []; "libobs.hide_scene_item.1" = [];
          "libobs.show_scene_item.2" = []; "libobs.hide_scene_item.2" = [];
          "libobs.show_scene_item.3" = []; "libobs.hide_scene_item.3" = [];
        };
        deinterlace_mode = 0; deinterlace_field_order = 0; monitoring_type = 0;
        canvas_uuid = "6c69626f-6273-4c00-9d88-c5136d61696e";
        private_settings = {};
      }
    ];

    groups = [];
    scene_order = [{name = "Game";}];
    current_scene = "Game";
    current_program_scene = "Game";
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
    "virtual-camera" = {type2 = 3;};
    modules = {
      tuna = {vlc_prev_hotkey = []; vlc_next_hotkey = [];};
      "transition-table" = {transitions = []; enable_hotkey = []; disable_hotkey = [];};
      "advanced-scene-switcher" = {
        sceneGroups = []; macros = [];
        macroSettings = {
          highlightExecuted = false; highlightConditions = false; highlightActions = false;
          newMacroCheckInParallel = false; newMacroRegisterHotkey = false;
          newMacroUseShortCircuitEvaluation = false; saveSettingsOnMacroChange = true;
        };
        variables = []; switches = []; ignoreWindows = []; screenRegion = []; pauseEntries = [];
        sceneRoundTrip = []; sceneTransitions = []; defaultTransitions = []; defTransitionDelay = 0;
        ignoreIdleWindows = []; idleTargetType = 0; idleSceneName = ""; idleTransitionName = "";
        idleEnable = false; idleTime = 60; executableSwitches = []; randomSwitches = [];
        fileSwitches = []; readEnabled = false; readPath = ""; writeEnabled = false; writePath = "";
        mediaSwitches = []; timeSwitches = []; audioSwitches = [];
        audioFallbackTargetType = 0; audioFallbackScene = ""; audioFallbackTransition = "";
        audioFallbackEnable = false;
        audioFallbackDuration = {value = {value = 0.0; type = 0;}; unit = 0; version = 1;};
        videoSwitches = []; interval = 300;
        noMatchScene = {sceneSelection = {type = 0; name = ""; canvasSelection = "Main";};};
        switch_if_not_matching = 0;
        noMatchDelay = {value = {value = 0.0; type = 0;}; unit = 0; version = 1;};
        cooldown = {value = {value = 0.0; type = 0;}; unit = 0; version = 1;};
        enableCooldown = false; active = true; startup_behavior = 0;
        autoStart = {
          event = 0; useAutoStartScene = false;
          sceneSelection = {type = 0; name = ""; canvasSelection = "Main";};
          name = ""; regexConfig = {enable = false; partial = false; options = 0;};
        };
        logLevel = 0; logLevelVersion = 1; showSystemTrayNotifications = false;
        disableHints = false; disableFilterComboboxFilter = false;
        warnPluginLoadFailure = true; hideLegacyTabs = true;
        priority0 = 10; priority1 = 0; priority2 = 2; priority3 = 8; priority4 = 6;
        priority5 = 9; priority6 = 7; priority7 = 4; priority8 = 1; priority9 = 5;
        priority10 = 3; threadPriority = 3;
        transitionOverrideOverride = false; adjustActiveTransitionType = true; lastImportPath = "";
        startHotkey = []; stopHotkey = []; toggleHotkey = [];
        newMacroHotkey = [{control = true; key = "OBS_KEY_N";}];
        upMacroSegmentHotkey = []; downMacroSegmentHotkey = []; removeMacroSegmentHotkey = [];
        tabWidgetOrder = [
          {generalTab = 0;} {macroTab = 1;} {windowTitleTab = 2;} {executableTab = 3;}
          {screenRegionTab = 4;} {mediaTab = 5;} {fileTab = 6;} {randomTab = 7;}
          {timeTab = 8;} {idleTab = 9;} {sceneSequenceTab = 10;} {audioTab = 11;}
          {videoTab = 12;} {sceneGroupTab = 13;} {transitionsTab = 14;} {pauseTab = 15;}
          {websocketConnectionTab = 16;} {twitchConnectionTab = 17;} {variableTab = 18;} {actionQueueTab = 19;}
        ];
        saveWindowGeo = false; windowPosX = 0; windowPosY = 0; windowWidth = 0; windowHeight = 0;
        macroListMacroEditSplitterPosition = []; version = "GITDIR-NOTFOUND";
        macroSearchSettings = {showAlways = false; searchType = 0; searchString = ""; regexConfig = {enable = false; partial = false; options = 0;};};
        tabSettings = {searchType = 0; searchString = ""; regexConfig = {enable = false; partial = false; options = 0;};};
        dockSettings = {searchType = 0; searchString = ""; regexConfig = {enable = false; partial = false; options = 0;};};
        addVariablesDock = false; websocketConnections = []; twitchConnections = [];
        actionQueues = []; dockWindows = {docks = [];}; alwaysShowTabs = false;
      };
      "scripts-tool" = [];
      "output-timer" = {
        streamTimerHours = 0; streamTimerMinutes = 0; streamTimerSeconds = 0;
        recordTimerHours = 0; recordTimerMinutes = 0; recordTimerSeconds = 0;
        autoStartStreamTimer = false; autoStartRecordTimer = false; pauseRecordTimer = false;
      };
    };
    version = 2;
  });

  globalIniFile = pkgs.writeText "obs-global.ini" ''
    [General]
    EnableAutoUpdates=false
    ConfirmOnExit=false
    LastVersion=30000000
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

  # Launcher: passes --profile (and optionally --collection / --startreplaybuffer)
  # directly so OBS always opens the right profile regardless of user.ini state.
  obsArgs =
    ["--profile" obsCfg.profile.name]
    ++ lib.optionals obsCfg.scenes.enable ["--collection" obsCfg.scenes.name];

  obs-launch = pkgs.writeShellApplication {
    name = "obs-launch";
    text = "exec obs ${lib.escapeShellArgs obsArgs} \"$@\"";
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
              preset = lib.mkOption {
                type = lib.types.enum ["p1" "p2" "p3" "p4" "p5" "p6" "p7"];
                default = "p4";
                description = ''
                  NVENC encoder preset (p1 = fastest/lowest quality, p7 = slowest/best quality).
                  p2 = low-latency, p4 = balanced, p7 = highest quality.
                '';
              };
              multipass = lib.mkOption {
                type = lib.types.enum ["disabled" "qres" "fullres"];
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

      # All config files use seed-if-absent so OBS can freely update them at runtime.
      # The --profile flag in obs-launch ensures the correct profile is always loaded
      # regardless of what global.ini says, so global.ini does not need force-writing.
      # Forcing global.ini on every activation resets LastVersion, which triggers OBS's
      # migration logic and causes "unable to migrate global configuration" errors.
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
          if [[ ! -f "$dest" ]] || [[ -L "$dest" ]]; then
            run install -m 644 "$src" "$dest"
          fi
        }

        seed "$WS_DIR/config.json"             ${websocketConfigFile}
        seed "$OBS_DIR/global.ini"             ${globalIniFile}
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
          "$mod, O, exec, ${obs-launch}/bin/obs-launch"
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
    # all go through obs-launch, which patches the profile before OBS reads it.
    xdg.desktopEntries."com.obsproject.Studio" = {
      name = "OBS Studio";
      genericName = "Streaming/Recording Software";
      comment = "Free and Open Source Streaming/Recording Software";
      exec = "${obs-launch}/bin/obs-launch %F";
      icon = "com.obsproject.Studio";
      terminal = false;
      type = "Application";
      categories = ["AudioVideo" "Recorder"];
      startupNotify = true;
    };
  };
}
