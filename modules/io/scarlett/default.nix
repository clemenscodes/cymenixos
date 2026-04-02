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
    # Systemd service: set Scarlett hardware controls at boot (Air on, 48V off)
    systemd.services.scarlett-init = {
      description = "Initialize Focusrite Scarlett 2i2 ALSA controls";
      wantedBy = ["multi-user.target"];
      after = ["sound.target"];
      path = [pkgs.alsa-utils];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.writeShellScript "scarlett-init" ''
          card=$(aplay -l 2>/dev/null | grep -i scarlett | head -1 | awk '{gsub(":", "", $2); print $2}')
          if [ -z "$card" ]; then
            echo "Scarlett card not found, skipping"
            exit 0
          fi
          amixer -c "$card" sset "Input 1 Air" on 2>/dev/null || true
          amixer -c "$card" sset "Input 1 Phantom Power" off 2>/dev/null || true
        ''}";
      };
    };

    # WirePlumber rule: configure Scarlett Input 1 (SM7B) as mono, 48kHz, 32-bit
    services.pipewire.wireplumber.extraConfig."51-scarlett-sm7b" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            {
              "node.name" = "~alsa_input.usb-Focusrite_Scarlett_2i2.*Mic1.*";
            }
          ];
          actions = {
            "update-props" = {
              "audio.format" = "S32LE";
              "audio.rate" = 48000;
              "audio.channels" = 1;
              "audio.position" = ["MONO"];
              "api.alsa.period-size" = 512;
              "resample.quality" = 10;
              "node.description" = "Scarlett 2i2 Input 1 (SM7B)";
            };
          };
        }
      ];
    };

    # PipeWire filter-chain: SM7B processing chain
    # Chain: RNNoise -> HP 80Hz -> Bell -2dB 250Hz -> Bell +2.5dB 3.5kHz -> Bell +2dB 7.5kHz -> HiShelf +2dB 12kHz
    # Output: "SM7B Processed" virtual source (becomes system default mic)
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
                  plugin = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa";
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
              inputs = ["rnnoise:Input"];
              outputs = ["eq_air:Out"];
            };
            "audio.channels" = 1;
            "audio.position" = ["MONO"];
            "capture.props" = {
              "node.name" = "capture.sm7b";
              "node.passive" = true;
              "target.object" = "alsa_input.usb-Focusrite_Scarlett_2i2_4th_Gen_S2AJV133401118-00.HiFi__Mic1__source";
            };
            "playback.props" = {
              "node.name" = "SM7B_Processed";
              "node.description" = "SM7B Processed (Shure SM7B + Scarlett 2i2)";
              "media.class" = "Audio/Source/Virtual";
              "audio.channels" = 1;
              "audio.position" = ["MONO"];
              "priority.session" = 2000;
            };
          };
        }
      ];
    };
  };
}
