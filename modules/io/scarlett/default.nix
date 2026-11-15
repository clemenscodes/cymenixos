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
          inputGain = lib.mkOption {
            type = lib.types.nullOr (lib.types.ints.between 0 69);
            default = null;
            description = ''
              Gain of input 1 in dB, set at boot. The SM7B chain expects its input at the
              level this gain gives, so it belongs to the declaration. null leaves the gain
              the device stored.
            '';
          };
          clipSafe = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = ''
              Clip Safe of input 1: the Scarlett lowers its own gain before the converter
              clips on a sudden peak (shout, laugh).
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
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1235", ATTR{idProduct}=="8219", ATTR{power/autosuspend}="-1", ATTR{power/control}="on"
    '';

    # Systemd service: set Scarlett hardware controls (Air on, 48V configurable)
    # Runs at boot (after udev settle) and is re-triggered by udev on hotplug.
    systemd.services.scarlett-init = {
      description = "Initialize Focusrite Scarlett 2i2 ALSA controls";
      after = ["systemd-udev-settle.service"];
      path = [pkgs.alsa-utils pkgs.gawk pkgs.coreutils];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = false;
        ExecStart = "${pkgs.writeShellScript "scarlett-init" ''
          # The scarlett-gen2 driver triggers a USB mode-switch reboot (standalone→driver
          # mode) ~15 s after connecting, which re-fires this udev trigger. Setting
          # phantom power on a freshly mode-switched device causes a second unrecoverable
          # disconnect. Guard: stamp is created after the first successful run (pre-
          # mode-switch) and is on tmpfs so it is cleared each boot. The device stores
          # phantom-power state in its own flash, so the post-mode-switch device already
          # has the correct value.
          if [ -f /run/scarlett-init.done ]; then
            echo "scarlett-init: already ran this boot cycle, skipping"
            exit 0
          fi

          # Wait for ALSA mixer controls to be registered after udev settle.
          sleep 2

          card=$(aplay -l 2>/dev/null | grep -i scarlett | head -1 | awk '{gsub(":", "", $2); print $2}')
          if [ -z "$card" ]; then
            echo "scarlett-init: Scarlett card not found, skipping"
            exit 0
          fi

          # Stamp only after confirming the card is present, so the wantedBy
          # multi-user.target dry-run (card absent at boot) does not block udev.
          touch /run/scarlett-init.done

          echo "scarlett-init: using card $card"
          # Firmware 2408+ removed the 'Air' enum value; available values are now
          # 'Off', 'Presence', 'Presence + Drive'. Leave at 'Off' — the software
          # filter-chain handles all presence/air EQ and 'Presence' stacks badly.
          amixer -c "$card" cset name='Line In 1 Air Capture Enum' 'Off'
          # 48V phantom power: controlled by useCloudLifter option.
          # CloudLifter/Fethead need phantom power to run their active circuit
          # but do not pass voltage through to the SM7B (safe for dynamic mics).
          amixer -c "$card" cset name='Line In 1-2 Phantom Power Capture Switch' ${phantomPower}
          ${lib.optionalString (scarlettCfg.inputGain != null) ''
            amixer -c "$card" cset name='Line In 1 Gain Capture Volume' ${toString scarlettCfg.inputGain}
          ''}
          amixer -c "$card" cset name='Line In 1 Safe Capture Switch' ${
            if scarlettCfg.clipSafe
            then "on"
            else "off"
          }
        ''}";
      };
    };

    # The chain runs in its own process, so everything it needs hangs off
    # filter-chain.service rather than pipewire.service (see the SIGKILL note at
    # the chain below for why it must not live in the daemon).
    #
    # pipewire ships filter-chain.service and the NixOS module already installs
    # it; it is simply not enabled by default. asDropin only appends the install
    # target and our environment instead of replacing the shipped unit, so its
    # BindsTo=pipewire.service and Restart=on-failure survive untouched.
    #
    # PipeWire 1.6+ no longer resolves absolute LADSPA plugin paths directly;
    # it searches LADSPA_PATH by filename. Set it to include every plugin used
    # by the filter-chain so the compressor and other nodes can be found. The
    # NixOS module already drops a LADSPA_PATH into this unit built from
    # configPackages' requiredLadspaPackages passthru, hence mkForce.
    systemd.user.services.filter-chain = {
      overrideStrategy = "asDropin";
      wantedBy = ["default.target"];
      environment.LADSPA_PATH = lib.mkForce (lib.makeSearchPath "lib/ladspa" [
        pkgs.lsp-plugins
        pkgs.deepfilternet
      ]);
    };

    # Declare SM7B_Processed as the default audio input device.
    # WirePlumber reads this at startup and sets it before any app connects.
    services.pipewire.wireplumber.extraConfig."50-sm7b-default" = {
      "wireplumber.settings" = {
        "default.audio.source" = "SM7B_Processed";
      };
    };

    # PipeWire filter-chain: SM7B processing chain (single source of truth for all apps)
    # high-pass, headroom, DeepFilterNet, expander, low shelf, compressor, presence,
    # air, de-esser, limiter
    #
    # The chain controls noise and dynamics and keeps the tone of the SM7B; its static
    # EQ is within about 2 dB of flat between 150 Hz and 14 kHz. It was tuned against
    # recordings of this mic in this room, played through a test instance of this
    # exact graph: -18 LUFS, -1.4 dBTP, noise floor -83 to -88 dBFS (about -64 raw),
    # loudness range about 8 LU (13 raw), identical results at quantum 64, 256, 2048.
    # OBS records this source processed and the Scarlett input raw on its own track,
    # so nothing here is baked into a recording that cannot be redone in post.
    #
    # Note: audio.position must use [FL] not [MONO] — MONO maps to port_id=1 in audioconvert
    #       DSP mode, exceeding the filter-chain's single-output SPA node → ENOSPC → all audio
    #       breaks system-wide.
    #
    # This MUST go to filter-chain.conf.d, never to pipewire.conf.d. A fragment in
    # pipewire.conf.d is loaded as context.modules into the pipewire daemon itself,
    # i.e. the very process that serves every device and every client. The chain's
    # DSP then runs on the daemon's realtime data thread, and when that thread
    # blows its RT budget (rtkit grants prio 20, RLIMIT_RTTIME is 200ms) the kernel
    # does not kill the chain, it SIGKILLs the whole daemon: no coredump, no log
    # line, just "code=killed, status=9/KILL". pipewire-pulse carries
    # BindsTo=pipewire.service and is force-stopped along with it, so a single
    # misbehaving mic chain takes down ALL audio (every sink, every source, every
    # app) in a per-second restart loop where wireplumber never finishes
    # enumerating and only auto_null remains. Happened for real after a nixpkgs
    # bump rebuilt the LADSPA plugins.
    # Upstream separates this on purpose: a standalone chain runs as its own
    # process via `pipewire -c filter-chain.conf` (filter-chain.service, shipped by
    # pipewire) which reads fragments from /etc/pipewire/filter-chain.conf.d/.
    # configPackages lands there through the NixOS module's pathsToLink
    # "/share/pipewire". A chain crash can then only ever take down the chain.
    services.pipewire.configPackages = [
      (pkgs.writeTextDir "share/pipewire/filter-chain.conf.d/51-sm7b-chain.conf" (builtins.toJSON {
        "context.modules" = [
          {
            name = "libpipewire-module-filter-chain";
            flags = ["nofail"];
            args = {
              "node.description" = "SM7B Processed";
              "media.name" = "SM7B Processed";
              "filter.graph" = {
                nodes = [
                  # 1-2. High-pass, 4th-order Butterworth at 85 Hz (two biquads with
                  # Q 0.5412 and 1.3066). Most of the raw noise floor of this room lies
                  # below 20 Hz (air, desk, fans) and mains hum at 50 Hz; the voice
                  # fundamental (about 85-155 Hz) stays. Measured: -16 dB at 60 Hz,
                  # -4 dB at 100 Hz.
                  {
                    type = "builtin";
                    name = "hp1";
                    label = "bq_highpass";
                    control = {
                      "Freq" = 85.0;
                      "Q" = 0.5412;
                    };
                  }
                  {
                    type = "builtin";
                    name = "hp2";
                    label = "bq_highpass";
                    control = {
                      "Freq" = 85.0;
                      "Q" = 1.3066;
                    };
                  }
                  # 3. 3 dB headroom. With 35 dB input gain the loudest shout reaches about
                  # -3 dBFS at the input and overshoots after the high-pass, and
                  # DeepFilterNet clips above full scale. From here on every level below
                  # is the one this stage delivers; the compressor makeup gives the 3 dB
                  # back.
                  {
                    type = "builtin";
                    name = "headroom";
                    label = "linear";
                    control = {
                      "Mult" = 0.7079;
                      "Add" = 0.0;
                    };
                  }
                  # 4. DeepFilterNet (neural noise suppression), at most 30 dB of
                  # attenuation so the voice stays natural. Replaces RNNoise and Speex
                  # (the Speex plugin rebuilt its state inside the realtime thread and
                  # the kernel killed the chain whenever a client linked).
                  {
                    type = "ladspa";
                    name = "denoise";
                    plugin = "${pkgs.deepfilternet}/lib/ladspa/libdeep_filter_ladspa.so";
                    label = "deep_filter_mono";
                    control = {
                      "Attenuation Limit (dB)" = 30.0;
                    };
                  }
                  # 5. Downward expander, 2:1 below -56 dBFS. DeepFilterNet
                  # leaves the tonal pump and fan noise (about 120 and 132 Hz, drifting
                  # with load, so no fixed notch); the expander lowers it in pauses only.
                  # Its sidechain ignores everything below 200 Hz so those tones cannot
                  # hold it open. Measured on silence: -80 to -94 dBFS, speech unchanged.
                  {
                    type = "ladspa";
                    name = "expander";
                    plugin = "${pkgs.lsp-plugins}/lib/ladspa/lsp-plugins-ladspa.so";
                    label = "http://lsp-plug.in/plugins/ladspa/expander_mono";
                    control = {
                      "Expander mode" = 0;
                      "Attack threshold (G)" = 0.0015849;
                      "Ratio" = 2.0;
                      "Attack time (ms)" = 2.0;
                      "Hold time (ms)" = 80.0;
                      "Release time (ms)" = 150.0;
                      "High-pass filter mode" = 2;
                      "High-pass filter frequency (Hz)" = 200.0;
                    };
                  }
                  # 6. Low shelf -3 dB at 200 Hz: the SM7B close up adds low-mid weight,
                  # and the compressor below lifts it further over a whole take.
                  {
                    type = "builtin";
                    name = "warmth";
                    label = "bq_lowshelf";
                    control = {
                      "Freq" = 200.0;
                      "Q" = 0.707;
                      "Gain" = -3.0;
                    };
                  }
                  # 7. Compressor 3:1 from -34 dBFS, 10 ms attack, 120 ms release, 6 dB
                  # knee, 21 dB makeup. Speech arrives here at about -36 dBFS RMS
                  # (-33 dBFS from the Scarlett at 35 dB gain, 3 dB headroom); the take
                  # ends at -18 LUFS with a loudness range of about 8 LU (13 LU raw).
                  {
                    type = "ladspa";
                    name = "compressor";
                    plugin = "${pkgs.lsp-plugins}/lib/ladspa/lsp-plugins-ladspa.so";
                    label = "http://lsp-plug.in/plugins/ladspa/compressor_mono";
                    control = {
                      "Attack threshold (G)" = 0.019953;
                      "Ratio" = 3.0;
                      "Attack time (ms)" = 10.0;
                      "Release time (ms)" = 120.0;
                      "Knee (G)" = 0.5012;
                      "Makeup gain (G)" = 11.220;
                    };
                  }
                  # 8-9. Presence +2 dB at 3.5 kHz and air +2 dB shelf from 9 kHz: the
                  # voice falls off steeply above 2 kHz on this mic.
                  {
                    type = "builtin";
                    name = "presence";
                    label = "bq_peaking";
                    control = {
                      "Freq" = 3500.0;
                      "Q" = 0.8;
                      "Gain" = 2.0;
                    };
                  }
                  {
                    type = "builtin";
                    name = "air";
                    label = "bq_highshelf";
                    control = {
                      "Freq" = 9000.0;
                      "Q" = 0.707;
                      "Gain" = 2.0;
                    };
                  }
                  # 10. De-esser on 5-12 kHz, 4:1 from -30 dBFS. Sibilant peaks drop from
                  # about 35 dB to 20-26 dB above the median of speech in that band.
                  {
                    type = "ladspa";
                    name = "deesser";
                    plugin = "${pkgs.lsp-plugins}/lib/ladspa/lsp-plugins-ladspa.so";
                    label = "http://lsp-plug.in/plugins/ladspa/deesser_mono";
                    control = {
                      "High-pass filter frequency (Hz)" = 5000.0;
                      "Low-pass filter frequency (Hz)" = 12000.0;
                      "Low-pass filter slope" = 1;
                      "Peak filter 1 on" = 0;
                      "Threshold (G)" = 0.031623;
                      "Ratio" = 4.0;
                      "Attack time (ms)" = 1.0;
                      "Release time (ms)" = 40.0;
                    };
                  }
                  # 11. Limiter at -1.5 dBFS with 5 ms lookahead. "Gain boost" off: it
                  # normalises the output back to 0 dBFS and clipped the shouts.
                  # Measured: -1.4 dBTP.
                  {
                    type = "ladspa";
                    name = "limiter";
                    plugin = "${pkgs.lsp-plugins}/lib/ladspa/lsp-plugins-ladspa.so";
                    label = "http://lsp-plug.in/plugins/ladspa/limiter_mono";
                    control = {
                      "Threshold (G)" = 0.84140;
                      "Gain boost" = 0;
                      "Lookahead (ms)" = 5.0;
                      "Automatic level regulation" = 0;
                    };
                  }
                ];
                links = [
                  {
                    output = "hp1:Out";
                    input = "hp2:In";
                  }
                  {
                    output = "hp2:Out";
                    input = "headroom:In";
                  }
                  {
                    output = "headroom:Out";
                    input = "denoise:Audio In";
                  }
                  {
                    output = "denoise:Audio Out";
                    input = "expander:Input";
                  }
                  {
                    output = "expander:Output";
                    input = "warmth:In";
                  }
                  {
                    output = "warmth:Out";
                    input = "compressor:Input";
                  }
                  {
                    output = "compressor:Output";
                    input = "presence:In";
                  }
                  {
                    output = "presence:Out";
                    input = "air:In";
                  }
                  {
                    output = "air:Out";
                    input = "deesser:Input";
                  }
                  {
                    output = "deesser:Output";
                    input = "limiter:Input";
                  }
                ];
                inputs = ["hp1:In"];
                outputs = ["limiter:Output"];
              };
              "capture.props" = {
                "node.name" = "capture.sm7b";
                "audio.position" = ["FL"];
                "stream.dont-remix" = true;
                "node.passive" = true;
                # Only ever capture from the Scarlett. If it is absent, wait for it
                # (dont-fallback) instead of grabbing some other source (e.g. the
                # webcam mic), and stay alive while waiting (linger) instead of
                # being torn down. See wireplumber find-defined-target.lua.
                "node.dont-fallback" = true;
                "node.linger" = true;
                "target.object" = "alsa_input.usb-Focusrite_Scarlett_2i2_4th_Gen_S2AJV133401118-00.HiFi__Mic1__source";
                # The chain sets the level; no stored volume may scale it (see below).
                "state.restore-props" = "false";
              };
              "playback.props" = {
                "node.name" = "SM7B_Processed";
                "node.description" = "SM7B Processed (Shure SM7B + Scarlett 2i2 4th Gen)";
                "media.class" = "Audio/Source";
                "audio.channels" = 1;
                "audio.position" = ["FL"];
                "priority.session" = 2000;
                # WirePlumber stores a volume per media.name and restores it on every
                # start. One stored for "SM7B Processed" (0.636, about -3.9 dB, typically
                # left by an app with automatic gain control) silently made the voice
                # 4 dB quieter than the chain delivers. The level is the chain's job.
                "state.restore-props" = "false";
              };
            };
          }
        ];
      }))
    ];
  };
}
