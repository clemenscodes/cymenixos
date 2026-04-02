{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.io;
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

    # PipeWire filter-chain: SM7B processing chain
    # HP(80Hz) → EQ
    #
    # Noise suppression is intentionally omitted here:
    # all tested PipeWire suppressors (RNNoise LADSPA, DeepFilterNet, LSP Expander, WebRTC AEC)
    # either cut word onsets or degrade voice quality. The OBS filter stack
    # (RNNoise + Speex -15dB) handles noise suppression cleanly at the application layer.
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
              inputs = ["eq_hp:In"];
              links = [
                {output = "eq_hp:Out";       input = "eq_low_cut:In";}
                {output = "eq_low_cut:Out";  input = "eq_presence:In";}
                {output = "eq_presence:Out"; input = "eq_clarity:In";}
                {output = "eq_clarity:Out";  input = "eq_air:In";}
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
