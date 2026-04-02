{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.io;
in {
  options = {
    modules = {
      io = {
        scarlett = {
          enable = lib.mkEnableOption "Enable Focusrite Scarlett 2i2 + SM7B declarative setup" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.scarlett.enable) {
    # Udev rule: trigger scarlett-init whenever a Focusrite device appears (boot + hotplug)
    # Vendor 1235 = Focusrite. Matching on SUBSYSTEM=="sound" ensures ALSA is already initialised.
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="sound", ATTRS{idVendor}=="1235", TAG+="systemd", ENV{SYSTEMD_WANTS}+="scarlett-init.service"
    '';

    # Systemd service: set Scarlett hardware controls (Air on, 48V off)
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
          # 48V phantom power: off (SM7B is dynamic — not needed, may cause harm)
          amixer -c "$card" cset name='Line In 1-2 Phantom Power Capture Switch' off
        ''}";
      };
    };


    # PipeWire filter-chain: SM7B processing chain
    # RNNoise (VAD 50%) → HP 80Hz → low-cut -2dB@250Hz → presence +2.5dB@3.5kHz → clarity +2dB@7.5kHz → air shelf +2dB@12kHz
    # Note: audio.position must use [FL] not [MONO] — MONO maps to port_id=1 in audioconvert DSP mode,
    #       which exceeds the filter-chain's single-output SPA node, causing ENOSPC and breaking all audio.
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
                {
                  type = "ladspa";
                  name = "rnnoise";
                  plugin = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                  label = "noise_suppressor_mono";
                  control = {
                    "VAD Threshold (%)" = 50;
                  };
                }
                {
                  type = "builtin";
                  name = "eq_hp";
                  label = "bq_highpass";
                  control = {
                    "Freq" = 80.0;
                    "Q" = 0.707;
                  };
                }
                {
                  type = "builtin";
                  name = "eq_low_cut";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 250.0;
                    "Q" = 1.5;
                    "Gain" = -2.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq_presence";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 3500.0;
                    "Q" = 1.2;
                    "Gain" = 2.5;
                  };
                }
                {
                  type = "builtin";
                  name = "eq_clarity";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 7500.0;
                    "Q" = 1.0;
                    "Gain" = 2.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq_air";
                  label = "bq_highshelf";
                  control = {
                    "Freq" = 12000.0;
                    "Q" = 0.707;
                    "Gain" = 2.0;
                  };
                }
              ];
              inputs = ["rnnoise:Input"];
              links = [
                {
                  output = "rnnoise:Output";
                  input = "eq_hp:In";
                }
                {
                  output = "eq_hp:Out";
                  input = "eq_low_cut:In";
                }
                {
                  output = "eq_low_cut:Out";
                  input = "eq_presence:In";
                }
                {
                  output = "eq_presence:Out";
                  input = "eq_clarity:In";
                }
                {
                  output = "eq_clarity:Out";
                  input = "eq_air:In";
                }
              ];
              outputs = ["eq_air:Out"];
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
              "node.description" = "SM7B Processed (Shure SM7B + Scarlett 2i2)";
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
