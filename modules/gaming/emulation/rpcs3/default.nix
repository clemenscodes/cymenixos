{
  inputs,
  pkgs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.gaming.emulation;
  ps3bios = import ./firmware {inherit pkgs;};
  # RPCS3 kann Firmware und Pakete ausschliesslich ueber die GUI installieren,
  # headless bricht es mit "Cannot perform installation in headless mode!" ab.
  # Der Patch laesst die vier Bestaetigungsdialoge dieses Pfades unter
  # RPCS3_UNATTENDED automatisch zusagen, damit das Provisioning ohne Klicks
  # durchlaeuft. Die beiden Erfolgsmeldungen danach haengen an GUI Settings und
  # werden ueber CurrentSettings.ini abgeschaltet, nicht ueber den Patch.
  rpcs3 = pkgs.rpcs3.overrideAttrs (oldAttrs: {
    # app-id.patch gives the window an app id in the first place. Without one no
    # taskbar can tie the window to a desktop entry, and StartupWMClass does not
    # help, because there is nothing for it to be compared against.
    patches = (oldAttrs.patches or []) ++ [./unattended-install.patch ./app-id.patch];
  });
  user = config.modules.users.name;
  rpcs3-provision = pkgs.writeShellApplication {
    name = "rpcs3-provision";
    runtimeInputs = [
      rpcs3
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.gawk
      pkgs.gnused
      pkgs.findutils
      pkgs.procps
      pkgs.imagemagick
      pkgs.util-linux
      pkgs.xvfb-run
    ];
    text = ''
      config_dir="$HOME/.config/rpcs3"
      log_file="$HOME/.cache/rpcs3/RPCS3.log"
      stamp_dir="$config_dir/.provisioned"
      pup="$config_dir/bios/PS3UPDAT.PUP"
      gui_settings="$config_dir/GuiConfigs/CurrentSettings.ini"

      mkdir -p "$stamp_dir" "$config_dir/GuiConfigs" "$HOME/.cache/rpcs3"

      if [ ! -f "$pup" ]; then
        echo "PS3UPDAT.PUP not found at $pup" >&2
        exit 1
      fi

      # RPCS3 schreibt CurrentSettings.ini im Betrieb selbst, sie kann daher
      # keine Verknuepfung in den Store sein. Die gewuenschten Schluessel werden
      # stattdessen vor jedem Lauf gesetzt, das bleibt idempotent und laesst
      # alles andere unangetastet.
      set_ini_key() {
        section="[$1]"
        key="$2"
        value="$3"
        touch "$gui_settings"
        awk -v section="$section" -v key="$key" -v value="$value" '
          /^\[/ {
            if (insec && !done) {
              print key "=" value
              done = 1
            }
            insec = ($0 == section)
            if (insec) {
              seensec = 1
            }
          }
          insec && index($0, key "=") == 1 {
            print key "=" value
            done = 1
            next
          }
          { print }
          END {
            if (!seensec) {
              print section
              print key "=" value
            } else if (!done) {
              print key "=" value
            }
          }
        ' "$gui_settings" > "$gui_settings.tmp" && mv "$gui_settings.tmp" "$gui_settings"
      }

      # Die Erfolgsmeldungen nach einer Installation sind modale Boxen, die auf
      # einen Klick warten. ShowBox ueberspringt sie, wenn ihr Schluessel auf
      # false steht.
      set_ini_key main_window infoBoxEnabledInstallPUP false
      set_ini_key main_window infoBoxEnabledInstallPKG false
      set_ini_key main_window infoBoxEnabledWelcome false
      set_ini_key Meta currentStylesheet "${cfg.rpcs3.theme}"

      if pgrep -x rpcs3 > /dev/null 2>&1; then
        echo "RPCS3 laeuft und ueberschreibt CurrentSettings.ini beim Beenden," >&2
        echo "die Oberflaechen Einstellungen greifen erst nach einem Neustart." >&2
      fi

      # RPCS3 beendet sich nach einer Installation ueber die Kommandozeile
      # nicht selbst, es bleibt im Hauptfenster stehen. Der Exitcode taugt also
      # nicht als Signal. Autoritativ ist stattdessen das Log, entweder eine
      # eindeutige Erfolgszeile oder das Erreichen der erwarteten Anzahl an
      # Erfolgszeilen. Erst danach wird der Prozess beendet.
      # Alle Instanzen schreiben in dieselbe RPCS3.log, ein Ueberbleibsel wuerde
      # also die Zaehlung des naechsten Laufs verfaelschen. xvfb-run startet
      # RPCS3 als Enkelprozess, ein kill auf die Startprozessnummer erwischt ihn
      # nicht. setsid macht den Start zum Anfuehrer einer eigenen Prozessgruppe,
      # dadurch beendet ein kill auf die negierte Nummer RPCS3 und Xvfb
      # zuverlaessig mit.
      launch_rpcs3() {
        : > "$log_file"
        setsid xvfb-run -a env -u WAYLAND_DISPLAY QT_QPA_PLATFORM=xcb RPCS3_UNATTENDED=1 \
          rpcs3 "$@" >/dev/null 2>&1 &
        rpcs3_pid=$!
      }

      stop_rpcs3() {
        kill -TERM -"$rpcs3_pid" >/dev/null 2>&1 || true
        waited=0
        while kill -0 -"$rpcs3_pid" >/dev/null 2>&1 && [ "$waited" -lt 10 ]; do
          sleep 1
          waited=$((waited + 1))
        done
        kill -KILL -"$rpcs3_pid" >/dev/null 2>&1 || true
        wait "$rpcs3_pid" >/dev/null 2>&1 || true
      }

      log_count() {
        grep -cE "$1" "$log_file" 2>/dev/null || true
      }

      # Wartet, bis das Log so viele Erfolgszeilen zeigt, wie Dateien uebergeben
      # wurden. Bricht ab, sobald RPCS3 eine Fehlermeldung loggt oder der
      # Prozess stirbt, damit ein Fehlschlag nicht bis zum Timeout haengt.
      await_install() {
        want_firmware="$1"
        want_packages="$2"
        want_licenses="$3"
        deadline="$4"
        waited=0
        while [ "$waited" -lt "$deadline" ]; do
          sleep 1
          waited=$((waited + 1))
          if [ "$(log_count "Successfully installed PS3 firmware")" -ge "$want_firmware" ] &&
            [ "$(log_count "Successfully installed .* \(title_id=")" -ge "$want_packages" ] &&
            [ "$(log_count "Successfully copied")" -ge "$want_licenses" ]; then
            return 0
          fi
          if grep -qE "installation failed|Failed to install|Failure!|Partially installed" "$log_file" 2>/dev/null; then
            return 1
          fi
          if ! kill -0 "$rpcs3_pid" 2>/dev/null; then
            return 1
          fi
        done
        return 1
      }

      if [ ! -f "$config_dir/dev_flash/vsh/etc/version.txt" ]; then
        echo "Installing PS3 firmware"
        launch_rpcs3 --installfw "$pup"
        if await_install 1 0 0 300; then
          stop_rpcs3
          echo "Firmware installed"
        else
          stop_rpcs3
          echo "Firmware installation failed" >&2
          exit 1
        fi
      fi

      # InstallPackages nimmt auch ein Verzeichnis und installiert dessen
      # Inhalt in einer Sitzung. Ein Start pro Verzeichnis statt pro Datei
      # spart den mehrsekuendigen Start von RPCS3 je Paket. get_dir_entries
      # steigt nicht in Unterverzeichnisse ab, deshalb wird jedes Blatt
      # einzeln uebergeben.
      install_tree() {
        root="$1"
        [ -d "$root" ] || return 0
        while IFS= read -r dir; do
          stamp="$stamp_dir/$(echo "$dir" | tr -c "A-Za-z0-9" "_").done"
          if [ -f "$stamp" ]; then
            continue
          fi
          pkgs=$(find "$dir" -maxdepth 1 -iname "*.pkg" | wc -l)
          lics=$(find "$dir" -maxdepth 1 \( -iname "*.rap" -o -iname "*.edat" \) | wc -l)
          echo "Installing $(basename "$dir") ($pkgs packages, $lics licenses)"
          launch_rpcs3 --installpkg "$dir"
          if await_install 0 "$pkgs" "$lics" 900; then
            stop_rpcs3
            touch "$stamp"
          else
            stop_rpcs3
            echo "Failed to install packages from $dir" >&2
            return 1
          fi
        done < <(find "$root" \( -iname "*.pkg" -o -iname "*.rap" -o -iname "*.edat" \) -printf "%h\n" | sort -u)
      }

      install_tree "${cfg.rpcs3.uncharted2.source}/Patches"
      install_tree "${cfg.rpcs3.uncharted2.source}/DLC"

      # Nur was unter dev_hdd0 liegt findet RPCS3 von allein. Disc Dumps
      # ausserhalb kennt es ausschliesslich ueber games.yml, eine Zuordnung von
      # Seriennummer auf das Verzeichnis mit der PS3_DISC.SFB. Ohne diesen
      # Eintrag bleibt die Spieleliste leer und die spielspezifische
      # Konfiguration greift nicht. RPCS3 schreibt die Datei selbst, sie kann
      # daher keine Verknuepfung in den Store sein.
      register_discs() {
        root="$1"
        [ -d "$root" ] || return 0
        games="$config_dir/games.yml"
        touch "$games"
        while IFS= read -r sfb; do
          disc=$(dirname "$sfb")
          sfo="$disc/PS3_GAME/PARAM.SFO"
          [ -f "$sfo" ] || continue
          serial=$(tr -d "\0" < "$sfo" | grep -oE "B[A-Z]{3}[0-9]{5}" | head -1)
          [ -n "$serial" ] || continue
          if grep -q "^$serial:" "$games"; then
            continue
          fi
          echo "Registering $serial at $disc"
          printf "%s: %s\n" "$serial" "$disc" >> "$games"
        done < <(find "$root" -name PS3_DISC.SFB)
      }

      register_discs "${cfg.rpcs3.uncharted2.source}"

      # Puts the game's own icon into the icon theme, so the desktop entry and
      # the taskbar find it under the name uncharted2. It comes out of the disc
      # dump, so it lives on a runtime path and cannot be a store path, which is
      # why this happens here and not in a derivation.
      #
      # A disc icon is 320 by 176 and therefore not square. It is centred on a
      # transparent background at 256 by 256, because an icon theme directory
      # promises a size, and an image of another size is dropped or stretched
      # depending on who is looking at it.
      install_game_icon() {
        src="${cfg.rpcs3.uncharted2.source}/Game/PS3_GAME/ICON0.PNG"
        dest="$HOME/.local/share/icons/hicolor/256x256/apps/uncharted2.png"
        [ -f "$src" ] || return 0
        [ "$dest" -nt "$src" ] && return 0
        mkdir -p "$(dirname "$dest")"
        magick "$src" -background none -gravity center -resize 256x256 \
          -extent 256x256 "$dest"
        echo "Installed game icon at $dest"
      }

      install_game_icon
      echo "RPCS3 provisioning complete"
    '';
  };
  uncharted = pkgs.writeShellApplication {
    name = "uncharted";
    runtimeInputs = [
      # `default` on purpose rather than a named variant. It is the one
      # attribute that survived joymouse being restructured, and a launcher has
      # no business caring whether it gets the glibc or the static build.
      inputs.joymouse.packages.${system}.default
      pkgs.procps
      pkgs.util-linux
    ];
    # The VPN stays up. This used to disconnect it for the length of a session
    # and reconnect afterwards, which put every other thing on the machine on
    # the open internet in order to fix one game.
    #
    # It was only ever needed because the game resolved its server by name and
    # a VPN with leak protection blocks port 53 to every destination. The IP
    # swap list in the game configuration answers those names inside RPCS3
    # instead, so no name lookup leaves the machine and nothing has to be
    # switched off. See the Net section of the Uncharted 2 configuration.
    text = ''
      # Starting a second instance gets you a modal box complaining about the
      # first one and nothing else, so there is nothing useful to do here.
      # The check comes before joymouse is started, because bailing out after
      # would leave exactly the stray daemon this launcher is careful to avoid.
      #
      # The name is the wrapped binary rather than `rpcs3`, because that is what
      # the process is actually called once the wrapper has exec'd into it.
      if pgrep -x .rpcs3-wrapped > /dev/null; then
        exit 0
      fi

      # Appear as Uncharted 2 rather than as the emulator. The patched RPCS3
      # reads this and hands it to the compositor as the window's app id, so the
      # taskbar finds uncharted2.desktop and shows the game's own icon instead
      # of the emulator's. Without it one binary can only ever be one
      # application.
      export RPCS3_DESKTOP_FILE_NAME=uncharted2

      # joymouse lives exactly as long as the game and not a moment longer.
      # PR_SET_PDEATHSIG has the kernel signal it the moment its parent goes
      # away, and the exec below makes RPCS3 that parent, in this very process.
      # So RPCS3 exiting, crashing, or being killed outright all end joymouse
      # the same way.
      #
      # A shell trap would not do. It cannot run when the launcher itself is
      # killed, and it would need a shell to stay alive alongside the game in
      # order to run in, which is one more process to outlive RPCS3 and hold
      # the pad open.
      setpriv --pdeathsig TERM joymouse &

      # exec, so this launcher IS the game rather than a parent watching it.
      # Nothing supervises, nothing polls, nothing waits on anything, so there
      # is nothing left that could wedge or be orphaned.
      exec ${rpcs3}/bin/.rpcs3-wrapped --no-gui /home/${user}/Games/U2/Game
    '';
  };
in {
  options = {
    modules = {
      gaming = {
        emulation = {
          rpcs3 = {
            enable = lib.mkEnableOption "Enable rpcs3 emulation (PlayStation 3)" // {default = false;};
            theme = lib.mkOption {
              type = lib.types.str;
              default = "Darker Style by TheMitoSan";
              description = "Name of the GUI stylesheet from GuiConfigs, without the qss suffix";
            };
            uncharted2 = {
              source = lib.mkOption {
                type = lib.types.str;
                default = "/mnt/raid/Games/U2";
                description = "Directory containing the Uncharted 2 disc dump, DLC and Patches";
              };
            };
            rpcn = {
              # rpcn.yml holds an account name, a password and a login token, so
              # it cannot be a file in this repository and it cannot be a store
              # symlink either, because everything in the store is world
              # readable. It arrives as a sops secret instead, decrypted at
              # activation and placed straight at the path RPCS3 reads.
              #
              # The secret is the WHOLE file, not just the credentials, so the
              # custom server list travels with it. That keeps this module free
              # of anybody's account and free of anybody's server.
              secret = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                example = "rpcn";
                description = ''
                  Name of the sops secret holding the complete rpcn.yml. Null
                  leaves RPCN configuration to RPCS3 itself.
                '';
              };
            };
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.rpcs3.enable) {
    systemd = {
      tmpfiles = {
        rules = [
          "L /home/${user}/Games/U2 - - - - ${cfg.rpcs3.uncharted2.source}"
        ];
      };
    };
    home-manager = lib.mkIf (config.modules.home-manager.enable) {
      users = {
        ${user} = {
          systemd = {
            user = {
              services = {
                rpcs3-provision = {
                  Unit = {
                    Description = "Provision RPCS3 firmware, game patches and DLC";
                  };
                  Service = {
                    Type = "oneshot";
                    ExecStart = "${rpcs3-provision}/bin/rpcs3-provision";
                  };
                  Install = {
                    WantedBy = ["default.target"];
                  };
                };
              };
            };
          };
          xdg = {
            # The attribute name is the file name, so this becomes
            # uncharted2.desktop. That matters: an icon is resolved by THEME
            # NAME, and that name has to equal the entry id and the icon file
            # name. uncharted2.desktop, Icon=uncharted2, uncharted2.png. An
            # absolute path in Icon does not render, which is exactly what this
            # entry used to carry, pointing at a file RPCS3 only ever creates
            # when somebody clicks Create Shortcut in its interface. That
            # directory was empty, so the entry had two separate reasons to
            # fall back to a placeholder.
            #
            # StartupWMClass is what lets a taskbar tie the RUNNING window back
            # to this entry. It matches the app id the launcher asks RPCS3 to
            # announce, see RPCS3_DESKTOP_FILE_NAME above.
            desktopEntries = {
              uncharted2 = {
                name = "Uncharted 2: Among Thieves™";
                type = "Application";
                categories = ["Game"];
                exec = "${uncharted}/bin/uncharted";
                icon = "uncharted2";
                noDisplay = false;
                startupNotify = true;
                terminal = false;
                settings = {
                  StartupWMClass = "uncharted2";
                };
              };
            };
          };
          # The RPCN account and the custom server list, decrypted at activation
          # and placed straight where RPCS3 reads it. The file lands outside the
          # store, readable by its owner only, which is why this is the one part
          # of the configuration that is not a symlink into a store path.
          #
          # It stays read only afterwards. RPCS3 saves a login token here so the
          # password does not have to be sent again, and it cannot do that now.
          # That costs nothing, because the password travels in the same secret,
          # so a login that cannot reuse a token simply performs one.
          sops = lib.mkIf (cfg.rpcs3.rpcn.secret != null) {
            secrets = {
              ${cfg.rpcs3.rpcn.secret} = {
                path = "/home/${user}/.config/rpcs3/rpcn.yml";
              };
            };
          };
          home = {
            packages = [
              pkgs.rusty-psn-gui
              rpcs3
              rpcs3-provision
              uncharted
            ];
            file = {
              ".config/rpcs3/bios" = {
                source = "${ps3bios}/bios";
              };
              # What patches EXIST. The community database, carried whole.
              # The emulator wide configuration. Every game without a file of its own runs
              # on this, so it is the baseline rather than a detail. It was the last
              # piece still living only on disk, which meant a fresh machine started
              # from RPCS3's own defaults and nobody would notice until a second game
              # behaved differently.
              #
              # Taken from the emulator itself, so what is declared is what ran. Checked
              # key by key against RPCS3's compiled in defaults: apart from the one line
              # below it is stock, which is the point. Per game tuning belongs in a per
              # game file, where it can be wrong for one title without being wrong for
              # all of them.
              #
              # The one addition is the anisotropic filter, forced to its maximum. On
              # this GPU it costs nothing measurable and it is the single setting that
              # improves every game at once.
              ".config/rpcs3/config.yml" = {
                text = ''
                  Core:
                    PPU Decoder: Recompiler (LLVM)
                    PPU Threads: 2
                    PPU Debug: false
                    PPU Calling History: false
                    Save LLVM logs: false
                    Use LLVM CPU: ""
                    Max LLVM Compile Threads: 0
                    PPU LLVM Greedy Mode: false
                    LLVM Precompilation: true
                    # Left alone deliberately, and not worth revisiting on
                    # this machine. The alternatives pin threads with affinity
                    # masks, and that table only has entries for CPU families
                    # 0x17, 0x18 and 0x19, meaning Zen through Zen 3. This host
                    # is family 0x1A, so no case matches, the mask stays at all
                    # cores, and every mode behaves identically. Changing it
                    # here would look like tuning and do nothing.
                    Thread Scheduler Mode: Operating System
                    Set DAZ and FTZ: false
                    SPU Decoder: Recompiler (LLVM)
                    SPU Reservation Busy Waiting Percentage 1: 100
                    SPU Reservation Busy Waiting Enabled: false
                    SPU GETLLAR Busy Waiting Percentage: 100
                    Disable SPU GETLLAR Spin Optimization: false
                    SPU Debug: false
                    MFC Debug: false
                    Preferred SPU Threads: 0
                    SPU delay penalty: 3
                    # Detects wait loops in SPU code and yields the thread
                    # instead of spinning. RPCS3's own description is
                    # improves performance and reduces CPU usage. The rare
                    # failure mode is audio stuttering, which is loud and
                    # obvious rather than subtle, so it is easy to catch.
                    SPU loop detection: true
                    Max SPURS Threads: 6
                    # Ties smaller compiled units together, so the SPU
                    # recompiler produces fewer and larger blocks and has more
                    # to optimise across. Safe is the compatibility choice
                    # rather than the fast one.
                    SPU Block Size: Mega
                    Accurate SPU DMA: false
                    Accurate SPU Reservations: true
                    Accurate Cache Line Stores: false
                    Accurate RSX reservation access: false
                    RSX FIFO Fetch Accuracy: Atomic
                    SPU Verification: true
                    SPU Cache: true
                    SPU Profiler: false
                    PPU Profiler: false
                    MFC Commands Shuffling Limit: 0
                    MFC Commands Timeout: 0
                    MFC Commands Shuffling In Steps: false
                    SPU XFloat Accuracy: Approximate
                    Accurate PPU 128-byte Reservation Op Max Length: 0
                    Stub PPU Traps: 0
                    Precise SPU Verification: false
                    PPU LLVM Java Mode Handling: true
                    PPU Vector NaN Handling: true
                    Use Accurate DFMA: true
                    PPU Set Saturation Bit: false
                    PPU Accurate Non-Java Mode: false
                    PPU Accurate Vector NaN Values: false
                    PPU Set FPCC Bits: false
                    Debug Console Mode: false
                    Hook static functions: false
                    Libraries Control:
                      []
                    HLE lwmutex: false
                    SPU LLVM Lower Bound: 0
                    SPU LLVM Upper Bound: 18446744073709551615
                    Clocks scale: 100
                    SPU Wake-Up Delay: 0
                    SPU Wake-Up Delay Thread Mask: 63
                    Max CPU Preempt Count: 0
                    Allow RSX CPU Preemptions: true
                    Sleep Timers Accuracy: As Host
                    Usleep Time Addend: 0
                    Performance Report Threshold: 500
                    Enable Performance Report: false
                    Assume External Debugger: false
                  VFS:
                    Enable /host_root/: false
                    Initialize Directories: true
                    Limit disk cache size: false
                    Disk cache maximum size (MB): 5120
                    Empty /dev_hdd0/tmp/: true
                  Video:
                    Renderer: Vulkan
                    Resolution: 1280x720
                    Aspect ratio: 16:9
                    Frame limit: Auto
                    Second Frame Limit: 0
                    MSAA: Auto
                    Shader Mode: Async Recompiler (multi-threaded)
                    Shader Precision: High
                    VSync Mode: Disabled
                    Write Color Buffers: false
                    Write Depth Buffer: false
                    Read Color Buffers: false
                    Read Depth Buffer: false
                    Handle RSX Memory Tiling: false
                    Log shader programs: false
                    Debug output: false
                    Debug overlay: false
                    Renderdoc Compatibility Mode: false
                    Use GPU texture scaling: false
                    Stretch To Display Area: false
                    Force High Precision Z buffer: false
                    Strict Rendering Mode: false
                    Disable ZCull Occlusion Queries: false
                    Disable Video Output: false
                    Disable Vertex Cache: false
                    Disable FIFO Reordering: false
                    Enable Frame Skip: false
                    Force CPU Blit: false
                    Disable On-Disk Shader Cache: false
                    Disable Vulkan Memory Allocator: false
                    Use full RGB output range: true
                    Strict Texture Flushing: false
                    # Offloads the large RSX memory transfers onto a worker
                    # thread. RPCS3 calls this an improvement for high core
                    # processors and a slowdown for weak ones. This host has
                    # thirty two threads, so it is on the good side of that.
                    Multithreaded RSX: true
                    Relaxed ZCULL Sync: false
                    Force Hardware MSAA Resolve: false
                    3D Display Enabled: false
                    3D Display Mode: Disabled
                    Screen size in inches: 24
                    Debug Program Analyser: false
                    Accurate ZCULL stats: true
                    Consecutive Frames To Draw: 1
                    Consecutive Frames To Skip: 1
                    Resolution Scale: 100
                    Anisotropic Filter Override: 16
                    Texture LOD Bias Addend: 0
                    Minimum Scalable Dimension: 16
                    Shader Compiler Threads: 0
                    Driver Recovery Timeout: 1000000
                    Driver Wake-Up Delay: 0
                    Vblank Rate: 60
                    Vblank NTSC Fixup: false
                    DECR memory layout: false
                    Allow Host GPU Labels: false
                    Disable MSL Fast Math: false
                    Disable Asynchronous Memory Manager: false
                    Output Scaling Mode: Bilinear
                    Record With Overlays: true
                    Disable Hardware ColorSpace Remapping: false
                    FidelityFX CAS Sharpening Intensity: 50
                    Vulkan:
                      Adapter: ""
                      Force primitive restart flag: false
                      Exclusive Fullscreen Mode: Automatic
                      Asynchronous Texture Streaming: false
                      Asynchronous Queue Scheduler: Safe
                      VRAM allocation limit (MB): 65536
                      Use Re-BAR for GPU uploads: true
                    Performance Overlay:
                      Enabled: false
                      Enable Framerate Graph: false
                      Enable Frametime Graph: false
                      Framerate datapoints: 50
                      Frametime datapoints: 170
                      Detail level: Medium
                      Framerate graph detail level: All
                      Frametime graph detail level: All
                      Metrics update interval (ms): 350
                      Font size (px): 10
                      Position: Top Left
                      Font: n023055ms.ttf
                      Horizontal Margin (%): 4
                      Vertical Margin (%): 7
                      Center Horizontally: false
                      Center Vertically: false
                      Opacity (%): 70
                      Body Color (hex): "#FFE138FF"
                      Body Background (hex): "#002339FF"
                      Title Color (hex): "#F26C24FF"
                      Title Background (hex): "#00000000"
                      Use Window Space: false
                    Shader Loading Dialog:
                      Allow custom background: true
                      Darkening effect strength: 30
                      Blur effect strength: 0
                  Audio:
                    Renderer: Cubeb
                    Audio Provider: CellAudio
                    RSXAudio Avport: HDMI 0
                    Dump to file: false
                    Convert to 16 bit: false
                    Audio Format: Stereo
                    Audio Formats: 0
                    Audio Channel Layout: Automatic
                    Audio Device: "@@@default@@@"
                    Master Volume: 100
                    Enable Buffering: true
                    Desired Audio Buffer Duration: 34
                    Enable Time Stretching: false
                    Disable Sampling Skip: false
                    Time Stretching Threshold: 75
                    Microphone Type: "Null"
                    Microphone Devices: "@@@@@@@@@@@@"
                    Music Handler: Qt
                  Input/Output:
                    Keyboard: "Null"
                    Mouse: Basic
                    Camera: "Null"
                    Camera type: Unknown
                    Camera flip: None
                    Camera ID: Default
                    SDL Camera ID: Default
                    Move: "Null"
                    Buzz emulated controller: "Null"
                    Turntable emulated controller: "Null"
                    GHLtar emulated controller: "Null"
                    Pad handler mode: Single-threaded
                    Keep pads connected: false
                    Pad handler sleep (microseconds): 1000
                    Background input enabled: true
                    Show move cursor: false
                    Paint move spheres: false
                    Allow move hue set by game: false
                    Lock overlay input to player one: false
                    Emulated Midi devices: Keyboardßßß@@@Keyboardßßß@@@Keyboardßßß@@@
                    Load SDL GameController Mappings: true
                    IO Debug overlay: false
                    Mouse Debug overlay: false
                    Fake Move Rotation Cone: 10
                    Fake Move Rotation Cone (Vertical): 10
                  System:
                    License Area: SCEA
                    Language: English (US)
                    Keyboard Type: English keyboard (US standard)
                    Enter button assignment: Enter with cross
                    Date Format: ddmmyyyy
                    Time Format: clock24
                    Console time offset (s): 0
                    System Name: RPCS3-582
                    Console PSID: 0x94F3031EAAABD51779A2BA59D6827F7B
                    HDD Model Name: ""
                    HDD Serial Number: ""
                    Process ARGV:
                      {}
                  Net:
                    Internet enabled: Disconnected
                    IP address: 0.0.0.0
                    Bind address: 0.0.0.0
                    DNS address: 8.8.8.8
                    IP swap list: ""
                    UPNP Enabled: false
                    PSN status: Disconnected
                    PSN Country: us
                    Clans Enabled: false
                  Savestate:
                    Start Paused: false
                    Suspend Emulation Savestate Mode: false
                    Compatible Savestate Mode: false
                    Inspection Mode Savestates: false
                    Save Disc Game Data: false
                    Maximum SaveState Files: 4
                    Maximum SaveState Files Space (MiB): 4096
                  Miscellaneous:
                    Automatically start games after boot: true
                    Exit RPCS3 when process finishes: false
                    Pause emulation on RPCS3 focus loss: false
                    Start games in fullscreen mode: true
                    Prevent display sleep while running games: true
                    Show trophy popups: true
                    Show RPCN popups: true
                    Show shader compilation hint: true
                    Show PPU compilation hint: true
                    Show autosave/autoload hint: false
                    Show pressure intensity toggle hint: true
                    Show analog limiter toggle hint: true
                    Show mouse and keyboard toggle hint: true
                    Show fatal error hints: false
                    Show capture hints: true
                    Use native user interface: true
                    Use recursive scan: false
                    GDB Server: 127.0.0.1:2345
                    Silence All Logs: false
                    Window Title Format: "FPS: %F | %R | %V | %T [%t]"
                    Pause Emulation During Home Menu: false
                    Play music during boot sequence: true
                    Enable GameMode: false
                  Log:
                    {}
                '';
              };
              ".config/rpcs3/patches/patch.yml" = {
                source = ./patch.yml;
              };
              # Which of them are switched ON. A separate file from the one
              # above and easy to miss, because the definitions being declared
              # looks like the job is done, while every patch still sits at its
              # default of off.
              #
              # The list is written out here rather than the finished YAML,
              # because the file is the same five lines repeated per patch with
              # one name changing, and a list of names is the part anybody
              # actually wants to read or edit. The hash identifies the game
              # binary, the version has to match the disc revision, and both
              # have to agree with an entry in patch.yml or the patch is simply
              # ignored.
              ".config/rpcs3/patch_config.yml" = {
                text =
                  let
                    hash = "PPU-a3a5789c12711291dfe16a7d5d81c906d2b4c0c2";
                    title = "Uncharted 2: Among Thieves";
                    serial = "BCES00757";
                    version = "01.09";
                    enabled = [
                      "Skip Intro"
                      "Unlock FPS"
                      "Disable Mesh Trimming"
                      "Enable GPU Lighting"
                      "Disable SPU Post-processing"
                      "Disable Depth of Field"
                      "Disable Velocity Motion Blur"
                      "Disable SSAO"
                      "Disable Motion Blur"
                    ];
                    # Built from plain strings and not from an indented block,
                    # because Nix strips the common indentation off a '' string
                    # and YAML is indentation. A block here silently produced a
                    # file where every patch name sat at the top level instead
                    # of under the hash, which parses fine and applies nothing.
                    entry =
                      name:
                      "  ${name}:\n"
                      + "    \"${title}\":\n"
                      + "      ${serial}:\n"
                      + "        ${version}:\n"
                      + "          Enabled: true\n";
                  in
                  "${hash}:\n" + lib.concatMapStrings entry enabled;
              };
              ".config/rpcs3/Icons/ui" = {
                source = "${rpcs3}/share/rpcs3/Icons/ui";
                recursive = true;
              };
              # RPCS3 legt in GuiConfigs seine CurrentSettings.ini an, das
              # Verzeichnis muss also beschreibbar bleiben. recursive verlinkt
              # jede Datei einzeln und laesst das Verzeichnis selbst frei.
              ".config/rpcs3/GuiConfigs" = {
                source = "${rpcs3}/share/rpcs3/GuiConfigs";
                recursive = true;
              };
              ".config/rpcs3/input_configs/active_input_configurations.yml" = {
                text = ''
                  Active Configurations:
                    global: Default
                '';
              };
              ".config/rpcs3/input_configs/global/Default.yml" = {
                text = ''
                  Player 1 Input:
                    Handler: SDL
                    Device: JoyMouse 1
                    Config:
                      Left Stick Left: LS X-
                      Left Stick Down: LS Y-
                      Left Stick Right: LS X+
                      Left Stick Up: LS Y+
                      Right Stick Left: RS X-
                      Right Stick Down: RS Y-
                      Right Stick Right: RS X+
                      Right Stick Up: RS Y+
                      Start: Start
                      Select: Back
                      PS Button: Guide
                      Square: West
                      Cross: South
                      Circle: East
                      Triangle: North
                      Left: Left
                      Down: Down
                      Right: Right
                      Up: Up
                      R1: RB
                      R2: RT
                      R3: RS
                      L1: LB
                      L2: LT
                      L3: LS
                      IR Nose: ""
                      IR Tail: ""
                      IR Left: ""
                      IR Right: ""
                      Tilt Left: ""
                      Tilt Right: ""
                      Motion Sensor X:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor Y:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor Z:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor G:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Orientation Reset Button: ""
                      Orientation Enabled: false
                      Pressure Intensity Button: ""
                      Pressure Intensity Percent: 50
                      Pressure Intensity Toggle Mode: false
                      Pressure Intensity Deadzone: 0
                      Analog Limiter Button: ""
                      Analog Limiter Toggle Mode: false
                      # JoyMouse is a virtual pad, so every shaping RPCS3 offers
                      # here is off. These are not RPCS3's defaults, they are
                      # chosen, and each one is off for its own reason.
                      #
                      # Multiplier 100 means unscaled. The one place to change
                      # aiming speed is joymouse's own sensitivity, because
                      # scaling here would clip against the axis range instead.
                      Left Stick Multiplier: 100
                      Right Stick Multiplier: 100
                      # A dead zone exists so a worn physical stick does not
                      # drift on its own. A virtual one never drifts, so this
                      # would only swallow the smallest movements.
                      Left Stick Deadzone: 0
                      Right Stick Deadzone: 0
                      # RPCS3 applies its anti dead zone PER AXIS, so it jumps
                      # by its full amount whenever one axis crosses zero, and a
                      # small circular movement comes out jagged. JoyMouse does
                      # the same job radially through deadzone_compensation, on
                      # the length only, leaving the direction untouched. Both
                      # at once would also compensate twice.
                      Left Stick Anti-Deadzone: 0
                      Right Stick Anti-Deadzone: 0
                      Left Trigger Threshold: 0
                      Right Trigger Threshold: 0
                      # Squircling pushes the round stick range out towards a
                      # square, which changes how far a diagonal reaches.
                      # JoyMouse already decides that, in its round gate and in
                      # diagonal_expansion, and two opinions about it fight.
                      Left Pad Squircling Factor: 0
                      Right Pad Squircling Factor: 0
                      Color Value R: 0
                      Color Value G: 0
                      Color Value B: 20
                      Blink LED when battery is below 20%: true
                      Use LED as a battery indicator: false
                      LED battery indicator brightness: 10
                      Player LED enabled: true
                      Large Vibration Motor Multiplier: 100
                      Small Vibration Motor Multiplier: 100
                      Switch Vibration Motors: false
                      Mouse Movement Mode: Relative
                      Mouse Deadzone X Axis: 60
                      Mouse Deadzone Y Axis: 60
                      Mouse Acceleration X Axis: 200
                      Mouse Acceleration Y Axis: 250
                      Left Stick Lerp Factor: 100
                      Right Stick Lerp Factor: 100
                      Analog Button Lerp Factor: 100
                      Trigger Lerp Factor: 100
                      Device Class Type: 0
                      Vendor ID: 1356
                      Product ID: 616
                    Buddy Device: ""
                  Player 2 Input:
                    Handler: "Null"
                    Device: "Null"
                    Config:
                      Left Stick Left: ""
                      Left Stick Down: ""
                      Left Stick Right: ""
                      Left Stick Up: ""
                      Right Stick Left: ""
                      Right Stick Down: ""
                      Right Stick Right: ""
                      Right Stick Up: ""
                      Start: ""
                      Select: ""
                      PS Button: ""
                      Square: ""
                      Cross: ""
                      Circle: ""
                      Triangle: ""
                      Left: ""
                      Down: ""
                      Right: ""
                      Up: ""
                      R1: ""
                      R2: ""
                      R3: ""
                      L1: ""
                      L2: ""
                      L3: ""
                      IR Nose: ""
                      IR Tail: ""
                      IR Left: ""
                      IR Right: ""
                      Tilt Left: ""
                      Tilt Right: ""
                      Motion Sensor X:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor Y:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor Z:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor G:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Orientation Reset Button: ""
                      Orientation Enabled: false
                      Pressure Intensity Button: ""
                      Pressure Intensity Percent: 50
                      Pressure Intensity Toggle Mode: false
                      Pressure Intensity Deadzone: 0
                      Analog Limiter Button: ""
                      Analog Limiter Toggle Mode: false
                      Left Stick Multiplier: 100
                      Right Stick Multiplier: 100
                      Left Stick Deadzone: 0
                      Right Stick Deadzone: 0
                      Left Stick Anti-Deadzone: 0
                      Right Stick Anti-Deadzone: 0
                      Left Trigger Threshold: 0
                      Right Trigger Threshold: 0
                      Left Pad Squircling Factor: 8000
                      Right Pad Squircling Factor: 8000
                      Color Value R: 0
                      Color Value G: 0
                      Color Value B: 0
                      Blink LED when battery is below 20%: true
                      Use LED as a battery indicator: false
                      LED battery indicator brightness: 50
                      Player LED enabled: true
                      Large Vibration Motor Multiplier: 100
                      Small Vibration Motor Multiplier: 100
                      Switch Vibration Motors: false
                      Mouse Movement Mode: Relative
                      Mouse Deadzone X Axis: 60
                      Mouse Deadzone Y Axis: 60
                      Mouse Acceleration X Axis: 200
                      Mouse Acceleration Y Axis: 250
                      Left Stick Lerp Factor: 100
                      Right Stick Lerp Factor: 100
                      Analog Button Lerp Factor: 100
                      Trigger Lerp Factor: 100
                      Device Class Type: 0
                      Vendor ID: 0
                      Product ID: 0
                    Buddy Device: "Null"
                  Player 3 Input:
                    Handler: "Null"
                    Device: "Null"
                    Config:
                      Left Stick Left: ""
                      Left Stick Down: ""
                      Left Stick Right: ""
                      Left Stick Up: ""
                      Right Stick Left: ""
                      Right Stick Down: ""
                      Right Stick Right: ""
                      Right Stick Up: ""
                      Start: ""
                      Select: ""
                      PS Button: ""
                      Square: ""
                      Cross: ""
                      Circle: ""
                      Triangle: ""
                      Left: ""
                      Down: ""
                      Right: ""
                      Up: ""
                      R1: ""
                      R2: ""
                      R3: ""
                      L1: ""
                      L2: ""
                      L3: ""
                      IR Nose: ""
                      IR Tail: ""
                      IR Left: ""
                      IR Right: ""
                      Tilt Left: ""
                      Tilt Right: ""
                      Motion Sensor X:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor Y:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor Z:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor G:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Orientation Reset Button: ""
                      Orientation Enabled: false
                      Pressure Intensity Button: ""
                      Pressure Intensity Percent: 50
                      Pressure Intensity Toggle Mode: false
                      Pressure Intensity Deadzone: 0
                      Analog Limiter Button: ""
                      Analog Limiter Toggle Mode: false
                      Left Stick Multiplier: 100
                      Right Stick Multiplier: 100
                      Left Stick Deadzone: 0
                      Right Stick Deadzone: 0
                      Left Stick Anti-Deadzone: 0
                      Right Stick Anti-Deadzone: 0
                      Left Trigger Threshold: 0
                      Right Trigger Threshold: 0
                      Left Pad Squircling Factor: 8000
                      Right Pad Squircling Factor: 8000
                      Color Value R: 0
                      Color Value G: 0
                      Color Value B: 0
                      Blink LED when battery is below 20%: true
                      Use LED as a battery indicator: false
                      LED battery indicator brightness: 50
                      Player LED enabled: true
                      Large Vibration Motor Multiplier: 100
                      Small Vibration Motor Multiplier: 100
                      Switch Vibration Motors: false
                      Mouse Movement Mode: Relative
                      Mouse Deadzone X Axis: 60
                      Mouse Deadzone Y Axis: 60
                      Mouse Acceleration X Axis: 200
                      Mouse Acceleration Y Axis: 250
                      Left Stick Lerp Factor: 100
                      Right Stick Lerp Factor: 100
                      Analog Button Lerp Factor: 100
                      Trigger Lerp Factor: 100
                      Device Class Type: 0
                      Vendor ID: 0
                      Product ID: 0
                    Buddy Device: "Null"
                  Player 4 Input:
                    Handler: "Null"
                    Device: "Null"
                    Config:
                      Left Stick Left: ""
                      Left Stick Down: ""
                      Left Stick Right: ""
                      Left Stick Up: ""
                      Right Stick Left: ""
                      Right Stick Down: ""
                      Right Stick Right: ""
                      Right Stick Up: ""
                      Start: ""
                      Select: ""
                      PS Button: ""
                      Square: ""
                      Cross: ""
                      Circle: ""
                      Triangle: ""
                      Left: ""
                      Down: ""
                      Right: ""
                      Up: ""
                      R1: ""
                      R2: ""
                      R3: ""
                      L1: ""
                      L2: ""
                      L3: ""
                      IR Nose: ""
                      IR Tail: ""
                      IR Left: ""
                      IR Right: ""
                      Tilt Left: ""
                      Tilt Right: ""
                      Motion Sensor X:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor Y:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor Z:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor G:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Orientation Reset Button: ""
                      Orientation Enabled: false
                      Pressure Intensity Button: ""
                      Pressure Intensity Percent: 50
                      Pressure Intensity Toggle Mode: false
                      Pressure Intensity Deadzone: 0
                      Analog Limiter Button: ""
                      Analog Limiter Toggle Mode: false
                      Left Stick Multiplier: 100
                      Right Stick Multiplier: 100
                      Left Stick Deadzone: 0
                      Right Stick Deadzone: 0
                      Left Stick Anti-Deadzone: 0
                      Right Stick Anti-Deadzone: 0
                      Left Trigger Threshold: 0
                      Right Trigger Threshold: 0
                      Left Pad Squircling Factor: 8000
                      Right Pad Squircling Factor: 8000
                      Color Value R: 0
                      Color Value G: 0
                      Color Value B: 0
                      Blink LED when battery is below 20%: true
                      Use LED as a battery indicator: false
                      LED battery indicator brightness: 50
                      Player LED enabled: true
                      Large Vibration Motor Multiplier: 100
                      Small Vibration Motor Multiplier: 100
                      Switch Vibration Motors: false
                      Mouse Movement Mode: Relative
                      Mouse Deadzone X Axis: 60
                      Mouse Deadzone Y Axis: 60
                      Mouse Acceleration X Axis: 200
                      Mouse Acceleration Y Axis: 250
                      Left Stick Lerp Factor: 100
                      Right Stick Lerp Factor: 100
                      Analog Button Lerp Factor: 100
                      Trigger Lerp Factor: 100
                      Device Class Type: 0
                      Vendor ID: 0
                      Product ID: 0
                    Buddy Device: "Null"
                  Player 5 Input:
                    Handler: "Null"
                    Device: "Null"
                    Config:
                      Left Stick Left: ""
                      Left Stick Down: ""
                      Left Stick Right: ""
                      Left Stick Up: ""
                      Right Stick Left: ""
                      Right Stick Down: ""
                      Right Stick Right: ""
                      Right Stick Up: ""
                      Start: ""
                      Select: ""
                      PS Button: ""
                      Square: ""
                      Cross: ""
                      Circle: ""
                      Triangle: ""
                      Left: ""
                      Down: ""
                      Right: ""
                      Up: ""
                      R1: ""
                      R2: ""
                      R3: ""
                      L1: ""
                      L2: ""
                      L3: ""
                      IR Nose: ""
                      IR Tail: ""
                      IR Left: ""
                      IR Right: ""
                      Tilt Left: ""
                      Tilt Right: ""
                      Motion Sensor X:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor Y:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor Z:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor G:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Orientation Reset Button: ""
                      Orientation Enabled: false
                      Pressure Intensity Button: ""
                      Pressure Intensity Percent: 50
                      Pressure Intensity Toggle Mode: false
                      Pressure Intensity Deadzone: 0
                      Analog Limiter Button: ""
                      Analog Limiter Toggle Mode: false
                      Left Stick Multiplier: 100
                      Right Stick Multiplier: 100
                      Left Stick Deadzone: 0
                      Right Stick Deadzone: 0
                      Left Stick Anti-Deadzone: 0
                      Right Stick Anti-Deadzone: 0
                      Left Trigger Threshold: 0
                      Right Trigger Threshold: 0
                      Left Pad Squircling Factor: 8000
                      Right Pad Squircling Factor: 8000
                      Color Value R: 0
                      Color Value G: 0
                      Color Value B: 0
                      Blink LED when battery is below 20%: true
                      Use LED as a battery indicator: false
                      LED battery indicator brightness: 50
                      Player LED enabled: true
                      Large Vibration Motor Multiplier: 100
                      Small Vibration Motor Multiplier: 100
                      Switch Vibration Motors: false
                      Mouse Movement Mode: Relative
                      Mouse Deadzone X Axis: 60
                      Mouse Deadzone Y Axis: 60
                      Mouse Acceleration X Axis: 200
                      Mouse Acceleration Y Axis: 250
                      Left Stick Lerp Factor: 100
                      Right Stick Lerp Factor: 100
                      Analog Button Lerp Factor: 100
                      Trigger Lerp Factor: 100
                      Device Class Type: 0
                      Vendor ID: 0
                      Product ID: 0
                    Buddy Device: "Null"
                  Player 6 Input:
                    Handler: "Null"
                    Device: "Null"
                    Config:
                      Left Stick Left: ""
                      Left Stick Down: ""
                      Left Stick Right: ""
                      Left Stick Up: ""
                      Right Stick Left: ""
                      Right Stick Down: ""
                      Right Stick Right: ""
                      Right Stick Up: ""
                      Start: ""
                      Select: ""
                      PS Button: ""
                      Square: ""
                      Cross: ""
                      Circle: ""
                      Triangle: ""
                      Left: ""
                      Down: ""
                      Right: ""
                      Up: ""
                      R1: ""
                      R2: ""
                      R3: ""
                      L1: ""
                      L2: ""
                      L3: ""
                      IR Nose: ""
                      IR Tail: ""
                      IR Left: ""
                      IR Right: ""
                      Tilt Left: ""
                      Tilt Right: ""
                      Motion Sensor X:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor Y:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor Z:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor G:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Orientation Reset Button: ""
                      Orientation Enabled: false
                      Pressure Intensity Button: ""
                      Pressure Intensity Percent: 50
                      Pressure Intensity Toggle Mode: false
                      Pressure Intensity Deadzone: 0
                      Analog Limiter Button: ""
                      Analog Limiter Toggle Mode: false
                      Left Stick Multiplier: 100
                      Right Stick Multiplier: 100
                      Left Stick Deadzone: 0
                      Right Stick Deadzone: 0
                      Left Stick Anti-Deadzone: 0
                      Right Stick Anti-Deadzone: 0
                      Left Trigger Threshold: 0
                      Right Trigger Threshold: 0
                      Left Pad Squircling Factor: 8000
                      Right Pad Squircling Factor: 8000
                      Color Value R: 0
                      Color Value G: 0
                      Color Value B: 0
                      Blink LED when battery is below 20%: true
                      Use LED as a battery indicator: false
                      LED battery indicator brightness: 50
                      Player LED enabled: true
                      Large Vibration Motor Multiplier: 100
                      Small Vibration Motor Multiplier: 100
                      Switch Vibration Motors: false
                      Mouse Movement Mode: Relative
                      Mouse Deadzone X Axis: 60
                      Mouse Deadzone Y Axis: 60
                      Mouse Acceleration X Axis: 200
                      Mouse Acceleration Y Axis: 250
                      Left Stick Lerp Factor: 100
                      Right Stick Lerp Factor: 100
                      Analog Button Lerp Factor: 100
                      Trigger Lerp Factor: 100
                      Device Class Type: 0
                      Vendor ID: 0
                      Product ID: 0
                    Buddy Device: "Null"
                  Player 7 Input:
                    Handler: "Null"
                    Device: "Null"
                    Config:
                      Left Stick Left: ""
                      Left Stick Down: ""
                      Left Stick Right: ""
                      Left Stick Up: ""
                      Right Stick Left: ""
                      Right Stick Down: ""
                      Right Stick Right: ""
                      Right Stick Up: ""
                      Start: ""
                      Select: ""
                      PS Button: ""
                      Square: ""
                      Cross: ""
                      Circle: ""
                      Triangle: ""
                      Left: ""
                      Down: ""
                      Right: ""
                      Up: ""
                      R1: ""
                      R2: ""
                      R3: ""
                      L1: ""
                      L2: ""
                      L3: ""
                      IR Nose: ""
                      IR Tail: ""
                      IR Left: ""
                      IR Right: ""
                      Tilt Left: ""
                      Tilt Right: ""
                      Motion Sensor X:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor Y:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor Z:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Motion Sensor G:
                        Axis: ""
                        Mirrored: false
                        Shift: 0
                      Orientation Reset Button: ""
                      Orientation Enabled: false
                      Pressure Intensity Button: ""
                      Pressure Intensity Percent: 50
                      Pressure Intensity Toggle Mode: false
                      Pressure Intensity Deadzone: 0
                      Analog Limiter Button: ""
                      Analog Limiter Toggle Mode: false
                      Left Stick Multiplier: 100
                      Right Stick Multiplier: 100
                      Left Stick Deadzone: 0
                      Right Stick Deadzone: 0
                      Left Stick Anti-Deadzone: 0
                      Right Stick Anti-Deadzone: 0
                      Left Trigger Threshold: 0
                      Right Trigger Threshold: 0
                      Left Pad Squircling Factor: 8000
                      Right Pad Squircling Factor: 8000
                      Color Value R: 0
                      Color Value G: 0
                      Color Value B: 0
                      Blink LED when battery is below 20%: true
                      Use LED as a battery indicator: false
                      LED battery indicator brightness: 50
                      Player LED enabled: true
                      Large Vibration Motor Multiplier: 100
                      Small Vibration Motor Multiplier: 100
                      Switch Vibration Motors: false
                      Mouse Movement Mode: Relative
                      Mouse Deadzone X Axis: 60
                      Mouse Deadzone Y Axis: 60
                      Mouse Acceleration X Axis: 200
                      Mouse Acceleration Y Axis: 250
                      Left Stick Lerp Factor: 100
                      Right Stick Lerp Factor: 100
                      Analog Button Lerp Factor: 100
                      Trigger Lerp Factor: 100
                      Device Class Type: 0
                      Vendor ID: 0
                      Product ID: 0
                    Buddy Device: "Null"
                '';
              };
              ".config/rpcs3/custom_configs/config_BCES00757.yml" = {
                text = ''
                  # Uncharted 2, BCES00757. This is the configuration that
                  # actually ran, taken from the emulator itself rather than
                  # written by hand, so what is declared and what was played
                  # are the same thing.
                  #
                  # Two fields are deliberately not carried over. The Vulkan
                  # adapter is left empty so RPCS3 picks the device present in
                  # the host, because naming one pins the config to a single
                  # machine and it silently falls back everywhere else. The
                  # console PSID is left to the global configuration, since it
                  # identifies the installation and has no business in a
                  # per-title file.
                  Audio:
                    Audio Channel Layout: Automatic
                    Audio Device: '@@@default@@@'
                    Audio Format: Stereo
                    Audio Formats: 0
                    Audio Provider: CellAudio
                    Convert to 16 bit: false
                    Desired Audio Buffer Duration: 100
                    Disable Sampling Skip: false
                    Dump to file: false
                    Enable Buffering: true
                    Enable Time Stretching: false
                    Master Volume: 100
                    Microphone Devices: '@@@@@@@@@@@@'
                    Microphone Type: "Null"
                    Music Handler: Qt
                    RSXAudio Avport: HDMI 0
                    Renderer: Cubeb
                    Time Stretching Threshold: 75
                  Core:
                    Accurate Cache Line Stores: false
                    Accurate PPU 128-byte Reservation Op Max Length: 0
                    # Back to RPCS3's default. Enabled it forces RSX pauses on
                    # SPU atomic operations, so it serialises the graphics
                    # thread against the SPUs by construction. It was the only
                    # accuracy setting here raised above stock.
                    Accurate RSX reservation access: false
                    Accurate SPU DMA: false
                    Accurate SPU Reservations: true
                    Allow RSX CPU Preemptions: true
                    Assume External Debugger: false
                    Clocks scale: 100
                    Debug Console Mode: false
                    Disable SPU GETLLAR Spin Optimization: false
                    Enable Performance Report: false
                    Enable TSX: Disabled
                    HLE lwmutex: false
                    Hook static functions: false
                    LLVM Precompilation: true
                    Libraries Control: []
                    MFC Commands Shuffling In Steps: false
                    MFC Commands Shuffling Limit: 0
                    MFC Commands Timeout: 0
                    MFC Debug: false
                    Max CPU Preempt Count: 0
                    Max LLVM Compile Threads: 0
                    Max SPURS Threads: 6
                    PPU Accurate Non-Java Mode: false
                    PPU Accurate Vector NaN Values: false
                    PPU Calling History: false
                    PPU Debug: false
                    PPU Decoder: Recompiler (LLVM)
                    PPU Fixup Vector NaN Values: false
                    PPU LLVM Greedy Mode: false
                    PPU LLVM Java Mode Handling: true
                    PPU Profiler: false
                    PPU Set FPCC Bits: false
                    PPU Set Saturation Bit: false
                    PPU Threads: 2
                    PPU Vector NaN Handling: true
                    Performance Report Threshold: 500
                    Precise SPU Verification: false
                    Preferred SPU Threads: 0
                    RSX FIFO Accuracy: Atomic
                    RSX FIFO Fetch Accuracy: Atomic
                    # As in the global configuration.
                    SPU Block Size: Mega
                    SPU Cache: true
                    SPU Debug: false
                    SPU Decoder: Recompiler (LLVM)
                    SPU GETLLAR Busy Waiting Percentage: 100
                    SPU LLVM Lower Bound: 0
                    SPU LLVM Upper Bound: 18446744073709551615
                    SPU Profiler: false
                    SPU Reservation Busy Waiting Enabled: false
                    SPU Reservation Busy Waiting Percentage: 0
                    SPU Reservation Busy Waiting Percentage 1: 100
                    SPU Verification: true
                    SPU Wake-Up Delay: 0
                    SPU Wake-Up Delay Thread Mask: 63
                    # The fastest of the three. Float accuracy on the SPUs buys
                    # correctness in games that need it, and this one is not
                    # known to. First thing to put back to Approximate if
                    # anything looks wrong in a way that is not obviously ZCULL.
                    SPU XFloat Accuracy: Relaxed
                    SPU delay penalty: 3
                    # As in the global configuration.
                    SPU loop detection: true
                    Save LLVM logs: false
                    Set DAZ and FTZ: false
                    Sleep Timers Accuracy: Usleep Only
                    Stub PPU Traps: 0
                    TSX Transaction First Limit: 800
                    TSX Transaction Second Limit: 2000
                    Thread Scheduler Mode: Operating System
                    Use Accurate DFMA: true
                    Use LLVM CPU: ""
                    Usleep Time Addend: 0
                    XFloat Accuracy: Approximate
                  Input/Output:
                    Allow move hue set by game: false
                    Background input enabled: true
                    Buzz emulated controller: "Null"
                    Camera: "Null"
                    Camera ID: Default
                    Camera flip: None
                    Camera type: Unknown
                    Emulated Midi devices: Keyboardßßß@@@Keyboardßßß@@@Keyboardßßß@@@
                    Fake Move Rotation Cone: 10
                    Fake Move Rotation Cone (Vertical): 10
                    GHLtar emulated controller: "Null"
                    IO Debug overlay: false
                    Keep pads connected: false
                    Keyboard: "Null"
                    Load SDL GameController Mappings: true
                    Lock overlay input to player one: false
                    Mouse: "Null"
                    Mouse Debug overlay: false
                    Move: "Null"
                    Pad handler mode: Single-threaded
                    Pad handler sleep (microseconds): 1000
                    Paint move spheres: false
                    SDL Camera ID: Default
                    Show move cursor: false
                    Turntable emulated controller: "Null"
                  Log: {}
                  Miscellaneous:
                    Automatically start games after boot: true
                    Enable GameMode: false
                    Exit RPCS3 when process finishes: false
                    GDB Server: 127.0.0.1:2345
                    Pause Emulation During Home Menu: false
                    Pause emulation on RPCS3 focus loss: false
                    Play music during boot sequence: true
                    Prevent display sleep while running games: true
                    Show PPU compilation hint: false
                    Show RPCN popups: true
                    Show analog limiter toggle hint: true
                    Show autosave/autoload hint: false
                    Show capture hints: true
                    Show fatal error hints: false
                    Show mouse and keyboard toggle hint: true
                    Show pressure intensity toggle hint: true
                    Show shader compilation hint: false
                    Show trophy popups: true
                    # Logging back on. This was the reason a broken RPCN
                    # connection showed nothing but a spinner: the emulator knew
                    # exactly what had failed and was told not to say so. The
                    # cost is some disk writes, the benefit is that the next
                    # problem is diagnosable at all.
                    Silence All Logs: false
                    Start games in fullscreen mode: true
                    Use native user interface: true
                    Use recursive scan: false
                    Window Title Format: 'FPS: %F | %R | %V | %T [%t]'
                  Net:
                    Bind address: 0.0.0.0
                    Clans Enabled: false
                    # Only consulted for a name the swap list below does not
                    # match, which with a wildcard is none. It stays as the
                    # honest fallback and as documentation of where the private
                    # server lives.
                    DNS address: 51.75.22.125
                    IP address: 0.0.0.0
                    # Every hostname the game asks for is answered with the
                    # private server, inside RPCS3, without a packet leaving the
                    # machine. The pattern is a real wildcard, RPCS3 turns `*`
                    # into `.*` and matches the hostname against it.
                    #
                    # This is not a nicety, it is what lets the game run inside
                    # a VPN. A DNS address alone means RPCS3 sends real queries
                    # to port 53, and a VPN with leak protection blocks port 53
                    # to every destination except its own resolver, its own
                    # server included. The query dies, the hostname never
                    # resolves, and the game sits at "Connecting..." for ever,
                    # while the RPCN connection itself is perfectly healthy
                    # because it is reached by address and never by name.
                    IP swap list: "*=51.75.22.125"
                    Internet enabled: Connected
                    PSN Country: us
                    PSN status: RPCN
                    # Off, because it cannot succeed and is not free. RPCS3
                    # asks the router to open the peer to peer port, there is no
                    # router to ask inside a VPN tunnel, and the search runs a
                    # full eight seconds into a timeout on every single launch.
                    UPNP Enabled: false
                  Savestate:
                    Compatible Savestate Mode: false
                    Inspection Mode Savestates: false
                    Maximum SaveState Files: 4
                    Maximum SaveState Files Space (MiB): 4096
                    Save Disc Game Data: false
                    Start Paused: false
                    Suspend Emulation Savestate Mode: false
                  System:
                    Console time offset (s): 0
                    Date Format: ddmmyyyy
                    Enter button assignment: Enter with cross
                    HDD Model Name: ""
                    HDD Serial Number: ""
                    Keyboard Type: German keyboard
                    Language: German
                    License Area: SCEE
                    PSID high: 0
                    PSID low: 0
                    Process ARGV: {}
                    System Name: RPCS3-577
                    Time Format: clock24
                  VFS:
                    Disk cache maximum size (MB): 5120
                    Empty /dev_hdd0/tmp/: true
                    Enable /host_root/: false
                    Initialize Directories: true
                    Limit disk cache size: false
                  Video:
                    3D Display Enabled: false
                    3D Display Mode: Disabled
                    Accurate ZCULL stats: false
                    Allow Host GPU Labels: false
                    # Free on this GPU, see the global configuration.
                    Anisotropic Filter Override: 16
                    Aspect ratio: 16:9
                    Consecutive Frames To Draw: 1
                    Consecutive Frames To Skip: 1
                    DECR memory layout: false
                    Debug Program Analyser: false
                    Debug output: false
                    Debug overlay: false
                    Disable Asynchronous Memory Manager: false
                    Disable FIFO Reordering: false
                    Disable Hardware ColorSpace Remapping: false
                    Disable MSL Fast Math: false
                    Disable On-Disk Shader Cache: false
                    Disable Vertex Cache: false
                    Disable Video Output: false
                    Disable Vulkan Memory Allocator: false
                    Disable ZCull Occlusion Queries: false
                    Driver Recovery Timeout: 1000000
                    Driver Wake-Up Delay: 20
                    Enable Frame Skip: false
                    FidelityFX CAS Sharpening Intensity: 50
                    Force CPU Blit: false
                    Force Hardware MSAA Resolve: false
                    Force High Precision Z buffer: false
                    Frame limit: Auto
                    Handle RSX Memory Tiling: false
                    Log shader programs: false
                    MSAA: Disabled
                    Minimum Scalable Dimension: 160
                    # As in the global configuration, and it matters more here.
                    # What gets offloaded is large memory copies, and the write
                    # and read buffer settings below produce exactly those in
                    # quantity.
                    Multithreaded RSX: true
                    Output Scaling Mode: FidelityFX Super Resolution
                    Performance Overlay:
                      Body Background (hex): '#002339FF'
                      Body Color (hex): '#FFE138FF'
                      Center Horizontally: false
                      Center Vertically: false
                      Detail level: None
                      Enable Framerate Graph: true
                      Enable Frametime Graph: false
                      Enabled: false
                      Font: n023055ms.ttf
                      Font size (px): 6
                      Framerate datapoints: 199
                      Framerate graph detail level: All
                      Frametime datapoints: 170
                      Frametime graph detail level: All
                      Horizontal Margin (%): 4
                      Horizontal Margin (px): 10
                      Metrics update interval (ms): 1000
                      Opacity (%): 10
                      Position: Top Left
                      Title Background (hex): '#00000000'
                      Title Color (hex): '#F26C24FF'
                      Use Window Space: false
                      Vertical Margin (%): 7
                      Vertical Margin (px): 10
                    Read Color Buffers: false
                    Read Depth Buffer: true
                    Record With Overlays: true
                    # The occlusion query path, already half loosened here since
                    # Accurate ZCULL stats is off. This is the other half.
                    # RPCS3 recommends the approximate middle for most games, so
                    # this is one step past the recommendation and the likeliest
                    # of these to show up as flickering or missing geometry.
                    Relaxed ZCULL Sync: true
                    Renderdoc Compatibility Mode: false
                    Renderer: Vulkan
                    Resolution: 1280x720
                    Resolution Scale: 150
                    Screen size in inches: 24
                    Second Frame Limit: 0
                    Shader Compiler Threads: 0
                    Shader Loading Dialog:
                      Allow custom background: true
                      Blur effect strength: 0
                      Darkening effect strength: 30
                    Shader Mode: Async Recompiler (multi-threaded)
                    Shader Precision: High
                    Stretch To Display Area: false
                    Strict Rendering Mode: false
                    Strict Texture Flushing: false
                    Texture LOD Bias Addend: 0
                    Use GPU texture scaling: false
                    Use full RGB output range: true
                    VSync: false
                    VSync Mode: Disabled
                    Vblank NTSC Fixup: false
                    Vblank Rate: 240
                    Vulkan:
                      Adapter: ""
                      Asynchronous Queue Scheduler: Safe
                      Asynchronous Texture Streaming: true
                      Asynchronous Texture Streaming 2: true
                      Exclusive Fullscreen Mode: Automatic
                      FidelityFX CAS Sharpening Intensity: 50
                      Force FIFO present mode: false
                      Force primitive restart flag: false
                      Use Re-BAR for GPU uploads: true
                      VRAM allocation limit (MB): 65536
                    Write Color Buffers: true
                    Write Depth Buffer: true
                '';
              };
            };
            persistence = lib.mkIf config.modules.boot.enable {
              "${config.modules.boot.impermanence.persistPath}" = {
                directories = [
                  ".config/rpcs3"
                  # The compiled caches: shaders, and the PPU and SPU code the
                  # recompilers produce. Tens of megabytes that cost minutes of
                  # stuttering to rebuild, and they were thrown away on every
                  # reboot because they live under .cache, which is wiped.
                  #
                  # Only the cache subdirectory, not all of .cache/rpcs3. The
                  # rest of it is the log and a lock file, and a lock file that
                  # survived a crash and a reboot is exactly what makes RPCS3
                  # refuse to start with a complaint about another instance.
                  ".cache/rpcs3/cache"
                ];
              };
            };
          };
        };
      };
    };
  };
}
