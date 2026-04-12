{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.io;
  speexLadspa = import ./speex-ladspa.nix {inherit pkgs;};
  scarlettCfg = cfg.scarlett;
  phantomPower =
    if scarlettCfg.useCloudLifter
    then "on"
    else "off";
in {
  options = {
    modules = {
      io = {
        scarlett = {
          enable = lib.mkEnableOption "Enable Focusrite Scarlett 2i2 + SM7B declarative setup" // {default = false;};
          useCloudLifter = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = ''
              Enable 48V phantom power for CloudLifter/Fethead inline preamps.
              The CloudLifter requires phantom power to operate its active circuit,
              but does not pass voltage through to the SM7B (safe for dynamic mics).
              Set to false if using the Scarlett directly without an inline preamp.
            '';
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.scarlett.enable) {
    # Udev rule: trigger scarlett-init whenever a Focusrite device appears (boot + hotplug)
    # Vendor 1235 = Focusrite. Matching on SUBSYSTEM=="sound" ensures ALSA is already initialised.
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="sound", ATTRS{idVendor}=="1235", TAG+="systemd", ENV{SYSTEMD_WANTS}+="scarlett-init.service"
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1235", ATTR{idProduct}=="8219", ATTR{power/autosuspend}="-1"
    '';

    # Systemd service: set Scarlett hardware controls (Air on, 48V configurable)
    # Runs at boot (after udev settle) and is re-triggered by udev on hotplug.
    systemd.services.scarlett-init = {
      description = "Initialize Focusrite Scarlett 2i2 ALSA controls";
      wantedBy = ["multi-user.target"];
      after = ["systemd-udev-settle.service"];
      path = [pkgs.alsa-utils pkgs.gawk];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = false;
        # Brief delay after udev settle to ensure ALSA mixer controls are registered.
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
        ExecStart = "${pkgs.writeShellScript "scarlett-init" ''
          card=$(aplay -l 2>/dev/null | grep -i scarlett | head -1 | awk '{gsub(":", "", $2); print $2}')
          if [ -z "$card" ]; then
            echo "scarlett-init: Scarlett card not found, skipping"
            exit 0
          fi
          echo "scarlett-init: using card $card"
          # Air mode: 'Presence' enables the high-frequency boost for dynamic mics like SM7B
          amixer -c "$card" cset name='Line In 1 Air Capture Enum' 'Presence'
          # 48V phantom power: controlled by useCloudLifter option.
          # CloudLifter/Fethead need phantom power to run their active circuit
          # but do not pass voltage through to the SM7B (safe for dynamic mics).
          amixer -c "$card" cset name='Line In 1-2 Phantom Power Capture Switch' ${phantomPower}
        ''}";
      };
    };

    # Declare SM7B_Processed as the default audio input device.
    # WirePlumber reads this at startup and sets it before any app connects.
    services.pipewire.wireplumber.extraConfig."50-sm7b-default" = {
      "wireplumber.settings" = {
        "default.audio.source" = "SM7B_Processed";
      };
    };

    # PipeWire filter-chain: SM7B processing chain (single source of truth for all apps)
    # HP(80Hz) → EQ → compressor → EQ → harmonics → maximiser → RNNoise → Speex
    #
    # All processing lives here. OBS captures SM7B_Processed and applies only a safety
    # limiter — duplicating suppression or compression in OBS causes artifacts.
    # Speex is a custom LADSPA derivation (speex-ladspa.nix) wrapping libspeexdsp.
    # No off-the-shelf LADSPA Speex plugin exists.
    # To revert noise suppression: remove nodes 12-13, restore outputs=["maximiser:Output"].
    #
    # Note: audio.position must use [FL] not [MONO] — MONO maps to port_id=1 in audioconvert
    #       DSP mode, exceeding the filter-chain's single-output SPA node → ENOSPC → all audio
    #       breaks system-wide.
    services.pipewire.extraConfig.pipewire."51-sm7b-chain" = {
      "context.modules" = [
        {
          name = "libpipewire-module-filter-chain";
          flags = ["nofail"];
          args = {
            "node.description" = "SM7B Processed";
            "media.name" = "SM7B Processed";
            "filter.graph" = {
              nodes = [
                # 1. High-pass: remove sub-80Hz rumble
                {
                  type = "builtin";
                  name = "eq_hp";
                  label = "bq_highpass";
                  control = {
                    "Freq" = 80.0;
                    "Q" = 0.707;
                  };
                }
                # 2. Low shelf: gentle warmth — SM7B is already dark so keep this subtle
                {
                  type = "builtin";
                  name = "eq_warmth";
                  label = "bq_lowshelf";
                  control = {
                    "Freq" = 150.0;
                    "Q" = 0.707;
                    "Gain" = 0.0;
                  };
                }
                # 3. Boom cut: SM7B proximity/body resonance around 300Hz
                {
                  type = "builtin";
                  name = "eq_box_cut";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 300.0;
                    "Q" = 1.0;
                    "Gain" = -4.0;
                  };
                }
                # 4. Box/mud cut: cardboard resonance and low-mid muddiness
                {
                  type = "builtin";
                  name = "eq_mud_cut";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 500.0;
                    "Q" = 1.2;
                    "Gain" = -3.0;
                  };
                }
                # 5. LSP Compressor: lookahead prevents onset cutting, evens out level
                # Attack raised from 6ms to 12ms — lets consonant transients through
                # before gain reduction kicks in, preserving natural punch and clarity.
                {
                  type = "ladspa";
                  name = "compressor";
                  plugin = "${pkgs.lsp-plugins}/lib/ladspa/lsp-plugins-ladspa.so";
                  label = "http://lsp-plug.in/plugins/ladspa/compressor_mono";
                  control = {
                    "Sidechain lookahead (ms)" = 5.0;
                    "Sidechain reactivity (ms)" = 5.0;
                    "Attack threshold (G)" = 0.12589; # -18 dB
                    "Attack time (ms)" = 12.0;
                    "Release time (ms)" = 60.0;
                    "Ratio" = 4.0;
                    "Knee (G)" = 0.5;
                    "Makeup gain (G)" = 1.0; # 0 dB — let the presence EQ do the lifting
                  };
                }
                # 6. Presence: voice forward, intelligible
                {
                  type = "builtin";
                  name = "eq_presence";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 3000.0;
                    "Q" = 0.9;
                    "Gain" = 5.0;
                  };
                }
                # 7. Definition: consonant crispness
                {
                  type = "builtin";
                  name = "eq_definition";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 5500.0;
                    "Q" = 1.2;
                    "Gain" = 2.0;
                  };
                }
                # 8. Clarity: sibilant detail without harshness
                {
                  type = "builtin";
                  name = "eq_clarity";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 8000.0;
                    "Q" = 1.0;
                    "Gain" = 1.5;
                  };
                }
                # 9. Air shelf: broadcast sparkle
                # Reduced from +5dB to +2dB — the Scarlett hardware Air/Presence mode
                # already adds ~4dB presence in this range; stacking both causes
                # harshness and sibilance around 8–12kHz.
                {
                  type = "builtin";
                  name = "eq_air";
                  label = "bq_highshelf";
                  control = {
                    "Freq" = 10000.0;
                    "Q" = 0.707;
                    "Gain" = 2.0;
                  };
                }
                # 10. Satan Maximiser: loudness/punch limiter
                # Decay raised from 8 to 40 samples (~0.8ms at 48kHz) — the 8-sample
                # setting causes intermodulation distortion on sharp transients.
                # 40 samples still limits aggressively while sounding clean.
                {
                  type = "ladspa";
                  name = "maximiser";
                  plugin = "${pkgs.ladspaPlugins}/lib/ladspa/satan_maximiser_1408.so";
                  label = "satanMaximiser";
                  control = {
                    "Decay time (samples)" = 40.0;
                    "Knee point (dB)" = -6.0;
                  };
                }
                # 11. RNNoise: neural noise suppressor — VAD-based, catches voice-frequency hum
                {
                  type = "ladspa";
                  name = "rnnoise";
                  plugin = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                  label = "noise_suppressor_mono";
                  control = {
                    "VAD Threshold (%)" = 30.0;
                  };
                }
                # 12. Speex: spectral subtraction suppressor — stationary noise floor estimation
                # Custom LADSPA derivation wrapping libspeexdsp (same lib OBS uses).
                # -15dB matches the OBS Speex filter setting exactly.
                {
                  type = "ladspa";
                  name = "speex";
                  plugin = "${speexLadspa}/lib/ladspa/libspeex_noise_suppressor_ladspa.so";
                  label = "speex_noise_suppressor_mono";
                  control = {
                    "Suppress Level (dB)" = -15.0;
                  };
                }
                # 13. Harmonic generator: tube-like even harmonics for richness.
                # Placed after noise suppression so the synthesized harmonics are not
                # treated as noise and suppressed — that interaction caused a hollow,
                # phasey "hallway" artifact. Magnitudes reduced slightly for the same reason.
                {
                  type = "ladspa";
                  name = "harmonics";
                  plugin = "${pkgs.ladspaPlugins}/lib/ladspa/harmonic_gen_1220.so";
                  label = "harmonicGen";
                  control = {
                    "Fundamental magnitude" = 1.0;
                    "2nd harmonic magnitude" = 0.10;
                    "3rd harmonic magnitude" = 0.03;
                    "4th harmonic magnitude" = 0.01;
                    "5th harmonic magnitude" = 0.0;
                    "6th harmonic magnitude" = 0.0;
                    "7th harmonic magnitude" = 0.0;
                    "8th harmonic magnitude" = 0.0;
                    "9th harmonic magnitude" = 0.0;
                    "10th harmonic magnitude" = 0.0;
                  };
                }
              ];
              inputs = ["eq_hp:In"];
              links = [
                {
                  output = "eq_hp:Out";
                  input = "eq_warmth:In";
                }
                {
                  output = "eq_warmth:Out";
                  input = "eq_box_cut:In";
                }
                {
                  output = "eq_box_cut:Out";
                  input = "eq_mud_cut:In";
                }
                {
                  output = "eq_mud_cut:Out";
                  input = "compressor:Input";
                }
                {
                  output = "compressor:Output";
                  input = "eq_presence:In";
                }
                {
                  output = "eq_presence:Out";
                  input = "eq_definition:In";
                }
                {
                  output = "eq_definition:Out";
                  input = "eq_clarity:In";
                }
                {
                  output = "eq_clarity:Out";
                  input = "eq_air:In";
                }
                {
                  output = "eq_air:Out";
                  input = "maximiser:Input";
                }
                {
                  output = "maximiser:Output";
                  input = "rnnoise:Input";
                }
                {
                  output = "rnnoise:Output";
                  input = "speex:Input";
                }
                {
                  output = "speex:Output";
                  input = "harmonics:Input";
                }
              ];
              outputs = ["harmonics:Output"];
            };
            "capture.props" = {
              "node.name" = "capture.sm7b";
              "audio.position" = ["FL"];
              "stream.dont-remix" = true;
              "node.passive" = true;
              "target.object" = "alsa_input.usb-Focusrite_Scarlett_2i2_4th_Gen_S2AJV133401118-00.HiFi__Mic1__source";
            };
            "playback.props" = {
              "node.name" = "SM7B_Processed";
              "node.description" = "SM7B Processed (Shure SM7B + Scarlett 2i2 4th Gen)";
              "media.class" = "Audio/Source";
              "audio.channels" = 1;
              "audio.position" = ["FL"];
              "priority.session" = 2000;
            };
          };
        }
      ];
    };
  };
}
