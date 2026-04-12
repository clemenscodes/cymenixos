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

  # Bitmask: enable first N audio tracks (1=0b1, 2=0b11, 3=0b111 … 6=0b111111)
  trackMask = builtins.foldl' (acc: _: acc * 2 + 1) 0 (lib.range 1 obsCfg.audio.tracks);

  # Bitmask: isolate a single track (track 1 → 1, track 2 → 2, track 3 → 4, …)
  singleTrackMixer = track: builtins.foldl' (acc: _: acc * 2) 1 (lib.range 1 (track - 1));

  # Files precomputed in the Nix store — copied to ~/.config/obs-studio on first run
  # (or on demand via obs-reset-config)
  websocketConfigFile = pkgs.writeText "obs-websocket-config.json" (
    builtins.toJSON {
      alerts_enabled = true;
      server_enabled = true;
      server_port = obsCfg.websocket.port;
      server_password = obsCfg.websocket.password;
    }
  );

  recordEncoderFile = pkgs.writeText "obs-record-encoder.json" (
    builtins.toJSON {
      rate_control = "CQP";
      preset = obsCfg.output.preset;
      multipass = obsCfg.output.multipass;
      cqp = obsCfg.output.cqp;
      lookahead = obsCfg.output.lookahead;
      adaptive_quantization = obsCfg.output.adaptiveQuantization;
      bf = obsCfg.output.bFrames;
    }
  );

  streamEncoderFile = pkgs.writeText "obs-stream-encoder.json" (
    builtins.toJSON {
      rate_control = "CBR";
      bitrate = obsCfg.stream.bitrate;
    }
  );

  # PipeWire application audio output capture (game sound, SDL, etc.)
  mkPipeWireAppSource = name: uuid: targetName: vol: {
    prev_ver = 536936448;
    inherit name uuid;
    id = "pipewire_audio_application_capture";
    versioned_id = "pipewire_audio_application_capture";
    settings = {
      TargetName = targetName;
    };
    mixers = 255;
    sync = 0;
    flags = 0;
    volume = vol;
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
    settings = {
      TargetName = targetName;
      TargetId = 0;
    };
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
    inherit
      name
      uuid
      id
      settings
      ;
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

  # OBS receives SM7B_Processed — already fully processed by the PipeWire filter-chain
  # (HP → EQ → compressor → EQ → harmonics → maximiser → RNNoise → Speex).
  # Only a safety limiter is needed here; duplicating noise suppression or compression
  # causes metallic artifacts and over-squashed dynamics.
  sm7bFilters = [
    (mkFilter "Limiter" "f98982cf-dd71-4a24-ac47-f1d5a3b13760" "limiter_filter" {threshold = -2.0;})
  ];

  # PipeWire desktop audio output capture (all system audio, no app filter)
  mkPipeWireOutputSource = name: uuid: {
    prev_ver = 536936448;
    inherit name uuid;
    id = "pipewire_audio_output_capture";
    versioned_id = "pipewire_audio_output_capture";
    settings = {};
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

  sceneCollectionFile = pkgs.writeText "obs-scene-collection.json" (
    builtins.toJSON {
      name = obsCfg.scenes.name;
      sources =
        [
          # 1. VK Capture
          {
            prev_ver = 536936448;
            name = "VK Capture";
            uuid = "cyme0001-0001-0001-0001-000000000004";
            id = "vkcapture-source";
            versioned_id = "vkcapture-source";
            settings = {
              show_cursor = false;
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
          # 2. GameSound (SDL Application via PipeWire app capture) — isolated to its track
          (
            (mkPipeWireAppSource "GameSound" "b84d7fe9-1968-45f5-864d-d656d56b019b" obsCfg.audio.gameSource obsCfg.audio.gameSourceVolume)
            // {mixers = singleTrackMixer obsCfg.audio.gameSourceTrack;}
          )
          # 3. Shure SM7B (PipeWire input with broadcast filter chain)
          (
            (mkPipeWireSource "Shure SM7B" "9e0dd964-6f7e-4aca-9f09-f118d39826ab" obsCfg.audio.mic sm7bFilters)
            // {
              mixers = singleTrackMixer obsCfg.audio.micTrack;
              settings = {
                TargetId = 43;
                TargetName = obsCfg.audio.mic;
              };
            }
          )
        ]
        ++ lib.optional keyboardOverlayCfg.enable {
          # Keyboard Overlay browser source
          prev_ver = 536936448;
          name = "Keyboard Overlay";
          uuid = "cyme0001-0001-0001-0001-000000000005";
          id = "browser_source";
          versioned_id = "browser_source";
          settings = {
            url = keyboardOverlayCfg.url;
            width = keyboardOverlayCfg.width;
            height = keyboardOverlayCfg.height;
            fps = keyboardOverlayCfg.fps;
            css = keyboardOverlayCfg.extraCss;
            shutdown = false;
            restart_when_active = false;
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
        ++ [
          # 6. Screen (full-screen PipeWire capture via xdg-desktop-portal)
          # RestoreToken is seeded declaratively via gdbus in home activation so OBS
          # restores without prompting. The flatpak permission store maps the token UUID
          # to the target output name (screenCapture.output).
          {
            prev_ver = 536936448;
            name = "Screen";
            uuid = "cyme0001-0001-0001-0001-000000000006";
            id = "pipewire-desktop-capture-source";
            versioned_id = "pipewire-desktop-capture-source";
            settings = {
              ShowCursor = true;
              RestoreToken = obsCfg.scenes.screenCapture.restoreToken;
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
          # 7. DesktopAudio (all PipeWire output — used by the Work scene)
          (mkPipeWireOutputSource "DesktopAudio" "cyme0001-0001-0001-0001-000000000008")
          # Game scene — contains VK Capture (video) + GameSound + SM7B (audio)
          {
            prev_ver = 536936448;
            name = "Game";
            uuid = "cyme0001-0001-0001-0001-000000000003";
            id = "scene";
            versioned_id = "scene";
            settings = {
              id_counter =
                if keyboardOverlayCfg.enable
                then 4
                else 3;
              custom_size = false;
              items =
                [
                  {
                    name = "VK Capture";
                    source_uuid = "cyme0001-0001-0001-0001-000000000004";
                    visible = true;
                    locked = false;
                    rot = 0.0;
                    scale_ref = {
                      x = 3840.0;
                      y = 2160.0;
                    };
                    align = 5;
                    bounds_type = 2;
                    bounds_align = 0;
                    bounds_crop = false;
                    crop_left = 0;
                    crop_top = 0;
                    crop_right = 0;
                    crop_bottom = 0;
                    id = 1;
                    group_item_backup = false;
                    pos = {
                      x = 0.0;
                      y = 0.0;
                    };
                    pos_rel = {
                      x = -1.7777777910232544;
                      y = -1.0;
                    };
                    scale = {
                      x = 1.0;
                      y = 1.0;
                    };
                    scale_rel = {
                      x = 1.0;
                      y = 1.0;
                    };
                    bounds = {
                      x = 3840.0;
                      y = 2160.0;
                    };
                    bounds_rel = {
                      x = 3.555555582046509;
                      y = 2.0;
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
                  }
                  {
                    name = "GameSound";
                    source_uuid = "b84d7fe9-1968-45f5-864d-d656d56b019b";
                    visible = true;
                    locked = false;
                    rot = 0.0;
                    scale_ref = {
                      x = 3840.0;
                      y = 2160.0;
                    };
                    align = 5;
                    bounds_type = 0;
                    bounds_align = 0;
                    bounds_crop = false;
                    crop_left = 0;
                    crop_top = 0;
                    crop_right = 0;
                    crop_bottom = 0;
                    id = 2;
                    group_item_backup = false;
                    pos = {
                      x = 0.0;
                      y = 0.0;
                    };
                    pos_rel = {
                      x = -1.7777777910232544;
                      y = -1.0;
                    };
                    scale = {
                      x = 1.0;
                      y = 1.0;
                    };
                    scale_rel = {
                      x = 1.0;
                      y = 1.0;
                    };
                    bounds = {
                      x = 0.0;
                      y = 0.0;
                    };
                    bounds_rel = {
                      x = 0.0;
                      y = 0.0;
                    };
                    scale_filter = "disable";
                    blend_method = "default";
                    blend_type = "normal";
                    show_transition = {
                      duration = 300;
                    };
                    hide_transition = {
                      duration = 300;
                    };
                    private_settings = {};
                  }
                  {
                    name = "Shure SM7B";
                    source_uuid = "9e0dd964-6f7e-4aca-9f09-f118d39826ab";
                    visible = true;
                    locked = false;
                    rot = 0.0;
                    scale_ref = {
                      x = 3840.0;
                      y = 2160.0;
                    };
                    align = 5;
                    bounds_type = 0;
                    bounds_align = 0;
                    bounds_crop = false;
                    crop_left = 0;
                    crop_top = 0;
                    crop_right = 0;
                    crop_bottom = 0;
                    id = 3;
                    group_item_backup = false;
                    pos = {
                      x = 0.0;
                      y = 0.0;
                    };
                    pos_rel = {
                      x = -1.7777777910232544;
                      y = -1.0;
                    };
                    scale = {
                      x = 1.0;
                      y = 1.0;
                    };
                    scale_rel = {
                      x = 1.0;
                      y = 1.0;
                    };
                    bounds = {
                      x = 0.0;
                      y = 0.0;
                    };
                    bounds_rel = {
                      x = 0.0;
                      y = 0.0;
                    };
                    scale_filter = "disable";
                    blend_method = "default";
                    blend_type = "normal";
                    show_transition = {
                      duration = 300;
                    };
                    hide_transition = {
                      duration = 300;
                    };
                    private_settings = {};
                  }
                ]
                ++ lib.optional keyboardOverlayCfg.enable (
                  let
                    bw = obsCfg.profile.baseWidth * 1.0;
                    bh = obsCfg.profile.baseHeight * 1.0;
                    halfH = bh / 2.0;
                    px = keyboardOverlayCfg.pos.x;
                    py = keyboardOverlayCfg.pos.y;
                  in {
                    name = "Keyboard Overlay";
                    source_uuid = "cyme0001-0001-0001-0001-000000000005";
                    visible = true;
                    locked = false;
                    rot = 0.0;
                    scale_ref = {
                      x = bw;
                      y = bh;
                    };
                    align = 5;
                    bounds_type = 2;
                    bounds_align = 0;
                    bounds_crop = false;
                    crop_left = 0;
                    crop_top = 0;
                    crop_right = 0;
                    crop_bottom = 0;
                    id = 4;
                    group_item_backup = false;
                    pos = {
                      x = px;
                      y = py;
                    };
                    pos_rel = {
                      x = (px - bw / 2.0) / halfH;
                      y = (py - bh / 2.0) / halfH;
                    };
                    scale = {
                      x = 1.0;
                      y = 1.0;
                    };
                    scale_rel = {
                      x = 1.0;
                      y = 1.0;
                    };
                    bounds = {
                      x = bw;
                      y = bh;
                    };
                    bounds_rel = {
                      x = bw / halfH;
                      y = bh / halfH;
                    };
                    scale_filter = "disable";
                    blend_method = "default";
                    blend_type = "normal";
                    show_transition = {
                      duration = 300;
                    };
                    hide_transition = {
                      duration = 300;
                    };
                    private_settings = {};
                  }
                );
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
            hotkeys =
              {
                "OBSBasic.SelectScene" = [];
                "libobs.show_scene_item.1" = [];
                "libobs.hide_scene_item.1" = [];
                "libobs.show_scene_item.2" = [];
                "libobs.hide_scene_item.2" = [];
                "libobs.show_scene_item.3" = [];
                "libobs.hide_scene_item.3" = [];
              }
              // lib.optionalAttrs keyboardOverlayCfg.enable {
                "libobs.show_scene_item.4" = [];
                "libobs.hide_scene_item.4" = [];
              };
            deinterlace_mode = 0;
            deinterlace_field_order = 0;
            monitoring_type = 0;
            canvas_uuid = "6c69626f-6273-4c00-9d88-c5136d61696e";
            private_settings = {};
          }
          # Work scene — Screen capture (video) + desktop sound + SM7B (audio)
          {
            prev_ver = 536936448;
            name = "Work";
            uuid = "cyme0001-0001-0001-0001-000000000007";
            id = "scene";
            versioned_id = "scene";
            settings = {
              id_counter = 3;
              custom_size = false;
              items = [
                {
                  name = "Screen";
                  source_uuid = "cyme0001-0001-0001-0001-000000000006";
                  visible = true;
                  locked = false;
                  rot = 0.0;
                  scale_ref = {
                    x = 3840.0;
                    y = 2160.0;
                  };
                  align = 5;
                  bounds_type = 2;
                  bounds_align = 0;
                  bounds_crop = false;
                  crop_left = 0;
                  crop_top = 0;
                  crop_right = 0;
                  crop_bottom = 0;
                  id = 1;
                  group_item_backup = false;
                  pos = {
                    x = 0.0;
                    y = 0.0;
                  };
                  pos_rel = {
                    x = -1.7777777910232544;
                    y = -1.0;
                  };
                  scale = {
                    x = 1.0;
                    y = 1.0;
                  };
                  scale_rel = {
                    x = 1.0;
                    y = 1.0;
                  };
                  bounds = {
                    x = 3840.0;
                    y = 2160.0;
                  };
                  bounds_rel = {
                    x = 3.555555582046509;
                    y = 2.0;
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
                }
                {
                  name = "DesktopAudio";
                  source_uuid = "cyme0001-0001-0001-0001-000000000008";
                  visible = true;
                  locked = false;
                  rot = 0.0;
                  scale_ref = {
                    x = 3840.0;
                    y = 2160.0;
                  };
                  align = 5;
                  bounds_type = 0;
                  bounds_align = 0;
                  bounds_crop = false;
                  crop_left = 0;
                  crop_top = 0;
                  crop_right = 0;
                  crop_bottom = 0;
                  id = 2;
                  group_item_backup = false;
                  pos = {
                    x = 0.0;
                    y = 0.0;
                  };
                  pos_rel = {
                    x = -1.7777777910232544;
                    y = -1.0;
                  };
                  scale = {
                    x = 1.0;
                    y = 1.0;
                  };
                  scale_rel = {
                    x = 1.0;
                    y = 1.0;
                  };
                  bounds = {
                    x = 0.0;
                    y = 0.0;
                  };
                  bounds_rel = {
                    x = 0.0;
                    y = 0.0;
                  };
                  scale_filter = "disable";
                  blend_method = "default";
                  blend_type = "normal";
                  show_transition = {
                    duration = 300;
                  };
                  hide_transition = {
                    duration = 300;
                  };
                  private_settings = {};
                }
                {
                  name = "Shure SM7B";
                  source_uuid = "9e0dd964-6f7e-4aca-9f09-f118d39826ab";
                  visible = true;
                  locked = false;
                  rot = 0.0;
                  scale_ref = {
                    x = 3840.0;
                    y = 2160.0;
                  };
                  align = 5;
                  bounds_type = 0;
                  bounds_align = 0;
                  bounds_crop = false;
                  crop_left = 0;
                  crop_top = 0;
                  crop_right = 0;
                  crop_bottom = 0;
                  id = 3;
                  group_item_backup = false;
                  pos = {
                    x = 0.0;
                    y = 0.0;
                  };
                  pos_rel = {
                    x = -1.7777777910232544;
                    y = -1.0;
                  };
                  scale = {
                    x = 1.0;
                    y = 1.0;
                  };
                  scale_rel = {
                    x = 1.0;
                    y = 1.0;
                  };
                  bounds = {
                    x = 0.0;
                    y = 0.0;
                  };
                  bounds_rel = {
                    x = 0.0;
                    y = 0.0;
                  };
                  scale_filter = "disable";
                  blend_method = "default";
                  blend_type = "normal";
                  show_transition = {
                    duration = 300;
                  };
                  hide_transition = {
                    duration = 300;
                  };
                  private_settings = {};
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
            hotkeys = {
              "OBSBasic.SelectScene" = [];
              "libobs.show_scene_item.1" = [];
              "libobs.hide_scene_item.1" = [];
              "libobs.show_scene_item.2" = [];
              "libobs.hide_scene_item.2" = [];
              "libobs.show_scene_item.3" = [];
              "libobs.hide_scene_item.3" = [];
            };
            deinterlace_mode = 0;
            deinterlace_field_order = 0;
            monitoring_type = 0;
            canvas_uuid = "6c69626f-6273-4c00-9d88-c5136d61696e";
            private_settings = {};
          }
        ];

      groups = [];
      scene_order = [
        {name = "Game";}
        {name = "Work";}
      ];
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
      "--minimize-to-tray"
      "--disable-missing-files-check"
      "--disable-updater"
      "--startreplaybuffer"
      "--startrecording"
    ]
    ++ lib.optionals obsCfg.scenes.enable [
      "--collection"
      obsCfg.scenes.name
    ];

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

  # obs-toggle: launch OBS if not running; gracefully stop it if it is.
  #
  # pgrep target: on NixOS the `obs` binary in PATH is a shell wrapper — the actual
  # running process is `.obs-wrapped`. pgrep -x obs never matches it; pgrep -x '.obs-wrapped' does.
  #
  # Shutdown order:
  #   1. stop replay buffer (flush buffered frames)
  #   2. stop recording (OBS muxes and seals the container)
  #   3. poll recording status up to 30 s until outputActive = false
  #   4. pkill obs (safe only after the file is sealed)
  obs-toggle = pkgs.writeShellApplication {
    name = "obs-toggle";
    runtimeInputs = [pkgs.jq pkgs.obs-cmd pkgs.procps];
    text = ''
      if pgrep -x '.obs-wrapped' > /dev/null 2>&1; then
        CONFIG_PATH="$HOME/.config/obs-studio/plugin_config/obs-websocket/config.json"
        if [[ -f "$CONFIG_PATH" ]]; then
          OBS_WEBSOCKET_PORT="$(jq -r '.server_port // empty' "$CONFIG_PATH")"
          OBS_WEBSOCKET_PASSWORD="$(jq -r '.server_password // empty' "$CONFIG_PATH")"
          if [[ -n "$OBS_WEBSOCKET_PORT" && -n "$OBS_WEBSOCKET_PASSWORD" ]]; then
            export OBS_WEBSOCKET_URL="obsws://localhost:$OBS_WEBSOCKET_PORT/$OBS_WEBSOCKET_PASSWORD"
            obs-cmd replay-buffer stop 2>/dev/null || true
            obs-cmd recording stop 2>/dev/null || true
            remaining=30
            while [ "$remaining" -gt 0 ]; do
              active=$(obs-cmd recording status 2>/dev/null | jq -r '.outputActive // false' 2>/dev/null || echo "false")
              if [ "$active" = "false" ]; then
                break
              fi
              sleep 1
              remaining=$((remaining - 1))
            done
          fi
        fi
        pkill obs 2>/dev/null || true
      else
        exec ${obs-launch}/bin/obs-launch
      fi
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
    runtimeInputs = [pkgs.jq pkgs.obs-cmd pkgs.procps];
    text = ''
      CONFIG_PATH="$HOME/.config/obs-studio/plugin_config/obs-websocket/config.json"

      if pgrep -x '.obs-wrapped' > /dev/null 2>&1; then
        if [[ -f "$CONFIG_PATH" ]]; then
          OBS_WEBSOCKET_PORT="$(jq -r '.server_port // empty' "$CONFIG_PATH")"
          OBS_WEBSOCKET_PASSWORD="$(jq -r '.server_password // empty' "$CONFIG_PATH")"
          if [[ -n "$OBS_WEBSOCKET_PORT" && -n "$OBS_WEBSOCKET_PASSWORD" ]]; then
            export OBS_WEBSOCKET_URL="obsws://localhost:$OBS_WEBSOCKET_PORT/$OBS_WEBSOCKET_PASSWORD"
            recording=$(obs-cmd recording status 2>/dev/null | jq -r '.outputActive // false' 2>/dev/null || echo "false")
            if [ "$recording" = "false" ]; then
              obs-cmd recording start 2>/dev/null || true
            fi
            replay=$(obs-cmd replay-buffer status 2>/dev/null | jq -r '.outputActive // false' 2>/dev/null || echo "false")
            if [ "$replay" = "false" ]; then
              obs-cmd replay-buffer start 2>/dev/null || true
            fi
          fi
        fi
      else
        exec ${obs-launch}/bin/obs-launch
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
    runtimeInputs = [pkgs.jq pkgs.obs-cmd pkgs.procps];
    text = ''
      CONFIG_PATH="$HOME/.config/obs-studio/plugin_config/obs-websocket/config.json"

      if pgrep -x '.obs-wrapped' > /dev/null 2>&1; then
        if [[ -f "$CONFIG_PATH" ]]; then
          OBS_WEBSOCKET_PORT="$(jq -r '.server_port // empty' "$CONFIG_PATH")"
          OBS_WEBSOCKET_PASSWORD="$(jq -r '.server_password // empty' "$CONFIG_PATH")"
          if [[ -n "$OBS_WEBSOCKET_PORT" && -n "$OBS_WEBSOCKET_PASSWORD" ]]; then
            export OBS_WEBSOCKET_URL="obsws://localhost:$OBS_WEBSOCKET_PORT/$OBS_WEBSOCKET_PASSWORD"
            obs-cmd replay-buffer stop 2>/dev/null || true
            obs-cmd recording stop 2>/dev/null || true
            remaining=30
            while [ "$remaining" -gt 0 ]; do
              active=$(obs-cmd recording status 2>/dev/null | jq -r '.outputActive // false' 2>/dev/null || echo "false")
              if [ "$active" = "false" ]; then
                break
              fi
              sleep 1
              remaining=$((remaining - 1))
            done
          fi
        fi
        pkill obs 2>/dev/null || true
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
                type = lib.types.enum [
                  "NV12"
                  "I420"
                  "I444"
                  "P010"
                  "I010"
                  "BGRA"
                ];
                default = "NV12";
                description = ''
                  OBS internal color format.
                  P010 = semi-planar 4:2:0 10-bit, NVENC native — use for HDR on NVIDIA.
                  NV12 = semi-planar 4:2:0 8-bit — safe default for SDR on any hardware.
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
              gameSourceTrack = lib.mkOption {
                type = lib.types.ints.between 1 6;
                default = 1;
                description = ''
                  OBS recording track for the GameSound source (1–6).
                  The source is isolated to this single track (all other tracks disabled).
                  Track assignments must be unique across sources for clean per-source stems.
                '';
              };
              micTrack = lib.mkOption {
                type = lib.types.ints.between 1 6;
                default = 2;
                description = ''
                  OBS recording track for the microphone (Shure SM7B) source (1–6).
                  The source is isolated to this single track (all other tracks disabled).
                  Track assignments must be unique across sources for clean per-source stems.
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
                  The Screen source restore token is seeded declaratively via gdbus in home
                  activation when scenes.screenCapture.restoreToken and .output are set.
                  Seeded once — OBS can freely modify it afterward. Use obs-reset-config to re-seed.
                '';
              };
              name = lib.mkOption {
                type = lib.types.str;
                default = "Default";
                description = "Scene collection name (shown in OBS menu and used as the filename).";
              };
              screenCapture = {
                output = lib.mkOption {
                  type = lib.types.str;
                  default = "";
                  description = ''
                    Wayland output name to capture in the Work scene (e.g. "DP-3", "HDMI-A-1").
                    Together with restoreToken, this is seeded into the xdg-desktop-portal permission
                    store on every home-manager activation via gdbus so OBS never prompts for a picker.
                    Run `hyprctl monitors` to find your output name.
                  '';
                };
                restoreToken = lib.mkOption {
                  type = lib.types.str;
                  default = "";
                  description = ''
                    UUID token that xdg-desktop-portal uses to look up the stored screen capture
                    selection. Generate once with `uuidgen` and pin it here. Home activation will
                    (re-)seed this token → output mapping in the permission store on every boot,
                    so the token survives impermanence wipes without manual re-selection.
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
      ];

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
          if [[ ! -f "$dest" ]] || [[ -L "$dest" ]]; then
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
        run chmod 600 "$WS_DIR/config.json" 2>/dev/null || true
        ${lib.optionalString (
          obsCfg.scenes.screenCapture.restoreToken != ""
          && obsCfg.scenes.screenCapture.output != ""
        ) ''
          # Seed the xdg-desktop-portal permission store so OBS restores the screen
          # capture source without showing a picker. Idempotent: Set overwrites if
          # the token already exists with the same data.
          #
          # Data format: (issuer, version, a{sv}) — hyprland portal v3 schema.
          # The portal validates output name against the running Wayland session; if
          # the output doesn't exist at OBS start time, it falls back to the picker.
          ${pkgs.glib}/bin/gdbus call \
            --session \
            --dest org.freedesktop.impl.portal.PermissionStore \
            --object-path /org/freedesktop/impl/portal/PermissionStore \
            --method org.freedesktop.impl.portal.PermissionStore.Set \
            "screencast" \
            true \
            "${obsCfg.scenes.screenCapture.restoreToken}" \
            "{}" \
            "<('hyprland', uint32 3, <{'output': <'${obsCfg.scenes.screenCapture.output}'>, 'withCursor': <uint32 1>, 'timeIssued': <uint64 0>, 'token': <'todo'>}>)>" \
            > /dev/null 2>&1 || true
        ''}
      '';
    };

    wayland.windowManager.hyprland = lib.mkIf (useHyprland && obsCfg.keybinds.enable) {
      settings = {
        bind = [
          "$mod, O, exec, ${obs-toggle}/bin/obs-toggle"
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
