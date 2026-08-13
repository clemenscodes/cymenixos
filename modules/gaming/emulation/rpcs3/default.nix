{
  inputs,
  pkgs,
  lib,
  ...
}:
{
  config,
  system,
  ...
}:
let
  cfg = config.modules.gaming.emulation;
  ps3bios = import ./firmware { inherit pkgs; };
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
    patches = (oldAttrs.patches or [ ]) ++ [
      ./unattended-install.patch
      ./app-id.patch
    ];
  });
  user = config.modules.users.name;
  # Uncharted 3 will not leave "Connecting..." until it has downloaded
  # campaign.config.txt.crypt over plain HTTP. The backend's own DNS answers
  # u3.campaign.config.s3.amazonaws.com with 194.13.80.115, where nginx has no
  # server block for that name and closes the connection without sending a
  # byte, so upstream that download cannot succeed at all. The per title IP
  # swap list sends the name to 127.0.0.1 instead and this is what answers
  # there.
  #
  # The bytes are the ones the very same host still returns through its
  # u3.final.prod vhost, which does answer, so nothing here is invented. The
  # queue address inside the file is stale and goes nowhere, 50.18.47.114 has
  # been dead since Naughty Dog shut the servers down, but that does not
  # matter. The address the game really dials comes out of
  # net18.bin.psarc.crypt, and this download only has to succeed.
  # Fetched rather than vendored, and fixed output, so the hash is what
  # guarantees the bytes and not the fact that somebody once committed them.
  # Plain HTTP is not a weakness here, the hash pins the content and the file
  # is public configuration either way.
  #
  # The URL carries the hostname the game itself sends, because that is the
  # only Host header the server will serve this file for, while --resolve aims
  # the connection at the machine that answers. Resolving the name normally
  # reaches Amazon, where the bucket was deleted, and resolving it through the
  # backend's DNS reaches a vhost that drops the connection.
  u3-campaign-config-file = pkgs.fetchurl {
    url = "http://u3.final.prod.s3.amazonaws.com/campaign.config.txt.crypt";
    curlOptsList = [
      "--resolve"
      "u3.final.prod.s3.amazonaws.com:80:194.13.80.115"
    ];
    hash = "sha256-eSLUcn/I67flt3KbwUCoX1ZCjNebLvxnqPkA5tZvngg=";
  };
  u3-campaign-config = pkgs.runCommand "u3-campaign-config" { } ''
    mkdir -p "$out"
    cp ${u3-campaign-config-file} "$out/campaign.config.txt.crypt"
  '';
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

      # Every declared game gets the same treatment, and a game whose files have
      # not arrived yet costs nothing: install_tree returns immediately for a
      # directory that is not there. So a title can be declared before its dump
      # exists and starts working on the next run of this service.
      #
      # Which discs EXIST is not decided here. That is games.yml, and it is
      # declared rather than written, see gameRegistry below.
      ${lib.concatStrings (
        lib.mapAttrsToList (_: game: ''
          install_tree "${game.source}/Patches"
          install_tree "${game.source}/DLC"
        '') games
      )}

      echo "RPCS3 provisioning complete"
    '';
  };
  # Every game that is switched on. Everything below is built per entry of this
  # set, so a new title is a declaration and nothing else.
  games = lib.filterAttrs (_: game: game.enable) cfg.rpcs3.games;
  # The icon, installed the way every other working launcher on this host does
  # it: as part of a package, so it lands in the profile next to an index.theme
  # and becomes part of an actual icon theme. A loose file dropped under the
  # home directory is not part of one, and a taskbar that resolves an icon by
  # theme name then finds nothing. That was the first attempt and it did not
  # render.
  #
  # The source is the disc icon at 256 by 256, because an icon theme directory
  # promises a size. A disc icon is 320 by 176 and sits on a black field, so it
  # is trimmed to the artwork first and then centred. Fitting the untrimmed
  # image into the square wasted a third of the width on empty background and
  # left the logo looking tiny in a launcher, and cropping to a square instead
  # cuts the title in half.
  #
  # The installed file name, the desktop entry id and the Icon key all have to
  # be the same word, and that word is the attribute name of the game. So
  # uncharted2.png, uncharted2.desktop, Icon=uncharted2. The name of the file
  # that is copied FROM does not matter, which is why every game keeps its
  # artwork under its own directory as plain icon.png.
  gameIcon =
    key: game:
    pkgs.runCommand "${key}-icon" { } ''
      install -Dm644 ${game.icon} \
        $out/share/icons/hicolor/256x256/apps/${key}.png
    '';
  gameLauncher =
    key: game:
    pkgs.writeShellApplication {
      name = game.command;
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
      # switched off. See the Net section of the per game configuration.
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

        # Appear as the game rather than as the emulator. The patched RPCS3
        # reads this and hands it to the compositor as the window's app id, so the
        # taskbar finds ${key}.desktop and shows the game's own icon instead
        # of the emulator's. Without it one binary can only ever be one
        # application.
        export RPCS3_DESKTOP_FILE_NAME=${key}

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
        # --game picks the profiles and the key assignment written down under
        # ${game.joymouse} in ~/.config/joymouse. What stands there is only ever
        # in force here, so the next game launched this way brings its own
        # without either of them having to be edited around the other.
        setpriv --pdeathsig TERM joymouse --game ${game.joymouse} &

        # exec, so this launcher IS the game rather than a parent watching it.
        # Nothing supervises, nothing polls, nothing waits on anything, so there
        # is nothing left that could wedge or be orphaned.
        exec ${rpcs3}/bin/.rpcs3-wrapped --no-gui /home/${user}/Games/${game.link}/${game.disc}
      '';
    };
  gamePackages = lib.concatLists (
    lib.mapAttrsToList (
      key: game: [ (gameLauncher key game) ] ++ lib.optional (game.icon != null) (gameIcon key game)
    ) games
  );
  # The attribute name is the file name, so this becomes uncharted2.desktop.
  # That matters: an icon is resolved by THEME NAME, and that name has to equal
  # the entry id and the icon file name. uncharted2.desktop, Icon=uncharted2,
  # uncharted2.png. An absolute path in Icon does not render, which is exactly
  # what this entry used to carry, pointing at a file RPCS3 only ever creates
  # when somebody clicks Create Shortcut in its interface. That directory was
  # empty, so the entry had two separate reasons to fall back to a placeholder.
  #
  # StartupWMClass is what lets a taskbar tie the RUNNING window back to this
  # entry. It matches the app id the launcher asks RPCS3 to announce, see
  # RPCS3_DESKTOP_FILE_NAME above.
  gameDesktopEntries = lib.mapAttrs (key: game: {
    name = game.displayName;
    type = "Application";
    categories = [ "Game" ];
    exec = "${gameLauncher key game}/bin/${game.command}";
    icon = if game.icon != null then key else "rpcs3";
    noDisplay = false;
    startupNotify = true;
    terminal = false;
    settings = {
      StartupWMClass = key;
    };
  }) games;
  # RPCS3 reads a per title configuration by serial, so the file name is the
  # serial and nothing else. A game without one simply runs on the emulator
  # wide config.yml.
  #
  # These go through xdg.configFile rather than home.file, which is the same
  # thing with ~/.config prepended, because the name of every one of them is
  # computed and a computed name cannot be written into the literal that holds
  # the files with fixed names.
  #
  # Like every other RPCS3 file here they go through rpcs3File below.
  gameCustomConfigs = lib.mapAttrs' (
    _: game:
    lib.nameValuePair "rpcs3/custom_configs/config_${game.serial}.yml" (rpcs3File {
      text = game.customConfig;
    })
  ) (lib.filterAttrs (_: game: game.customConfig != null) games);
  # Patch definitions that the community database does not carry.
  #
  # Keeping them out of patch.yml is the point. That file is carried whole and
  # a local edit to it would have to be redone by hand on every update of it.
  #
  # There is exactly ONE such file and it has to be called imported_patch.yml.
  # RPCS3 loads that name and patch.yml and nothing else from this directory,
  # which was established by putting a deliberately broken file there under
  # another name and getting no complaint out of the emulator, then renaming it
  # and watching both patches apply. The *_patch.yml that turns up in the RPCS3
  # binary is the filter of a file dialog, not a search pattern.
  #
  # So this is one file for the whole emulator rather than one per game. An
  # option per game would promise something the emulator cannot deliver, and
  # two games declaring one would silently overwrite each other.
  extraPatchFile = lib.optionalAttrs (cfg.rpcs3.extraPatches != null) {
    "rpcs3/patches/imported_patch.yml" = rpcs3File {
      source = cfg.rpcs3.extraPatches;
    };
  };
  # Every declared RPCS3 file lands in the home directory as a real copy rather
  # than as a symlink into the store, and every switch writes it again.
  #
  # mutable, because RPCS3 writes its own configuration back. It cannot do that
  # to a read only store symlink, and what it does instead differs from file to
  # file and is never what is declared here. As a copy the file reads and writes
  # like any other.
  #
  # force, because otherwise Home Manager first moves whatever it finds aside,
  # to serial.yml.home-manager-backup next to it. On the second switch that
  # backup is already there, Home Manager refuses to back up over a backup and
  # aborts the whole activation. A state that blocks itself after exactly one
  # run. That is what happened here.
  #
  # Nothing that was meant to be kept is lost either. What the file should
  # contain is declared here, not in whatever RPCS3 wrote into it last.
  rpcs3File =
    file:
    file
    // {
      force = true;
      mutable = true;
    };
  # Nur was unter dev_hdd0 liegt findet RPCS3 von allein. Disc Dumps ausserhalb
  # kennt es ausschliesslich ueber games.yml, eine Zuordnung von Seriennummer
  # auf das Verzeichnis mit der PS3_DISC.SFB. Ohne Eintrag bleibt die
  # Spieleliste leer und die spielspezifische Konfiguration greift nicht.
  #
  # Die Datei wird DEKLARIERT und nicht fortgeschrieben. Vorher hat das
  # Provisioning sie mit >> ergaenzt, und weil RPCS3 sie ohne abschliessenden
  # Zeilenumbruch schreibt, klebte der erste zusaetzliche Eintrag an den letzten
  # bestehenden. Eine Zeile mit zwei Zuordnungen ist kein YAML, RPCS3 verwarf
  # daraufhin die GANZE Datei und zeigte gar keine Spiele mehr. Ein Anhaengen
  # kennt eben nur den einen Eintrag, den es gerade schreibt, nie den
  # Sollzustand. Als Store Symlink ist der Sollzustand dagegen das Einzige, was
  # existieren kann, und jeder Switch stellt ihn wieder her.
  #
  # Dass RPCS3 selbst nicht mehr hineinschreiben kann, ist kein Verlust,
  # sondern der Zweck: hier stehen genau die Spiele, die deklariert sind.
  #
  # Eingetragen wird der Pfad UEBER den Link unter ~/Games, derselbe, den auch
  # der Launcher bootet, damit die Platte, auf der der Dump liegt, an keiner
  # dauerhaften Stelle auftaucht.
  gameRegistry = lib.concatStrings (
    lib.mapAttrsToList (
      _: game: "${game.serial}: /home/${user}/Games/${game.link}/${game.disc}\n"
    ) games
  );
  # Which patches are switched ON, for every game at once, because RPCS3 keeps
  # them all in one file keyed by the hash of the game binary.
  #
  # This is a separate file from patch.yml above and easy to miss, because the
  # definitions being declared looks like the job is done, while every patch
  # still sits at its default of off.
  #
  # Per game only the list of names is written down, because the YAML is the
  # same five lines repeated per patch with one name changing, and a list of
  # names is the part anybody actually wants to read or edit. The hash
  # identifies the game binary, the version has to match the disc revision, and
  # both have to agree with an entry in patch.yml or the patch is simply
  # ignored.
  #
  # Built from plain strings and not from an indented block, because Nix strips
  # the common indentation off a '' string and YAML is indentation. A block here
  # silently produced a file where every patch name sat at the top level instead
  # of under the hash, which parses fine and applies nothing.
  gamePatchConfig = lib.concatStrings (
    lib.mapAttrsToList (
      _: game:
      "${game.patch.hash}:\n"
      + lib.concatMapStrings (
        name:
        "  ${name}:\n"
        + "    \"${game.patch.title}\":\n"
        + "      ${game.serial}:\n"
        + "        ${game.patch.version}:\n"
        + "          Enabled: true\n"
      ) game.patch.enabled
    ) (lib.filterAttrs (_: game: game.patch.enabled != [ ]) games)
  );
in
{
  options = {
    modules = {
      gaming = {
        emulation = {
          rpcs3 = {
            enable = lib.mkEnableOption "Enable rpcs3 emulation (PlayStation 3)" // {
              default = false;
            };
            theme = lib.mkOption {
              type = lib.types.str;
              default = "Darker Style by TheMitoSan";
              description = "Name of the GUI stylesheet from GuiConfigs, without the qss suffix";
            };
            extraPatches = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              example = lib.literalExpression "./games/gta5/patch.yml";
              description = ''
                Patch definitions the community database does not carry,
                installed as imported_patch.yml beside patch.yml. RPCS3 loads
                exactly those two files out of its patches directory, so this
                is one file for the whole emulator and not one per game. Null
                means patch.yml is all there is.
              '';
            };
            # One entry per game. Everything that differs between titles lives
            # here and nothing else does, so adding a game is a declaration
            # rather than an edit spread over the module.
            #
            # This module already declares uncharted2 below. Those definitions
            # merge with whatever is declared elsewhere, so a configuration adds
            # a title without repeating the one that is already there.
            games = lib.mkOption {
              default = { };
              description = ''
                Games to provision, launch and configure. The attribute name is
                the identity of the game across the whole desktop: it is the
                desktop entry id, the icon name in the theme and the app id the
                window announces, and all three have to agree.
              '';
              example = lib.literalExpression ''
                {
                  uncharted3 = {
                    source = "/mnt/raid/Games/U3";
                    displayName = "Uncharted 3: Drake's Deception™";
                    serial = "BCES01175";
                    icon = ./uncharted3/icon.png;
                    customConfig = builtins.readFile ./uncharted3/config.yml;
                    patch = {
                      title = "Uncharted 3: Drake's Deception";
                      hash = "PPU-0000000000000000000000000000000000000000";
                      version = "01.20";
                      enabled = ["Skip Intro" "Unlock FPS"];
                    };
                  };
                }
              '';
              type = lib.types.attrsOf (
                lib.types.submodule (
                  {
                    name,
                    config,
                    ...
                  }:
                  {
                    options = {
                      enable = lib.mkEnableOption "Enable this game" // {
                        default = true;
                      };
                      source = lib.mkOption {
                        type = lib.types.str;
                        description = ''
                          Directory containing the disc dump, its DLC and its
                          Patches. It does not have to exist yet, a game whose files
                          are still missing is simply skipped when provisioning.
                        '';
                      };
                      disc = lib.mkOption {
                        type = lib.types.str;
                        default = "Game";
                        description = "Subdirectory of source holding PS3_DISC.SFB";
                      };
                      link = lib.mkOption {
                        type = lib.types.str;
                        default = builtins.baseNameOf config.source;
                        defaultText = lib.literalExpression "builtins.baseNameOf source";
                        description = ''
                          Name of the symlink under ~/Games that points at source,
                          so the game is booted from a path that does not depend on
                          where the dump is kept.
                        '';
                      };
                      command = lib.mkOption {
                        type = lib.types.str;
                        default = name;
                        defaultText = lib.literalExpression "the attribute name";
                        description = "Name of the launcher on PATH";
                      };
                      displayName = lib.mkOption {
                        type = lib.types.str;
                        description = "Name shown by the launcher and the taskbar";
                      };
                      serial = lib.mkOption {
                        type = lib.types.str;
                        example = "BCES00757";
                        description = ''
                          Title id of the disc. RPCS3 names the per game
                          configuration after it, so it has to be the serial of the
                          dump in source and not that of another region.
                        '';
                      };
                      joymouse = lib.mkOption {
                        type = lib.types.str;
                        default = name;
                        defaultText = lib.literalExpression "the attribute name";
                        description = ''
                          Profile joymouse is started with, meaning the section of
                          that name in ~/.config/joymouse.
                        '';
                      };
                      icon = lib.mkOption {
                        type = lib.types.nullOr lib.types.path;
                        default = null;
                        example = lib.literalExpression "./uncharted2/icon.png";
                        description = ''
                          The disc icon at 256 by 256, trimmed to the artwork and
                          centred. Null falls back to the emulator's own icon.
                        '';
                      };
                      customConfig = lib.mkOption {
                        type = lib.types.nullOr lib.types.lines;
                        default = null;
                        example = lib.literalExpression "builtins.readFile ./uncharted2/config.yml";
                        description = ''
                          The per title configuration RPCS3 keeps under
                          custom_configs. Null runs the game on the emulator wide
                          config.yml.
                        '';
                      };
                      patch = {
                        title = lib.mkOption {
                          type = lib.types.str;
                          default = config.displayName;
                          defaultText = lib.literalExpression "displayName";
                          description = ''
                            The name of the game AS patch.yml spells it. It is a key
                            there, so a stray trademark sign or a missing subtitle
                            means every patch below is ignored.
                          '';
                        };
                        hash = lib.mkOption {
                          type = lib.types.str;
                          default = "";
                          example = "PPU-a3a5789c12711291dfe16a7d5d81c906d2b4c0c2";
                          description = ''
                            Hash of the game binary the patches belong to, as
                            patch.yml and the RPCS3 log spell it.
                          '';
                        };
                        version = lib.mkOption {
                          type = lib.types.str;
                          default = "";
                          example = "01.09";
                          description = "Disc revision the patches were written for";
                        };
                        enabled = lib.mkOption {
                          type = lib.types.listOf lib.types.str;
                          default = [ ];
                          example = [
                            "Skip Intro"
                            "Unlock FPS"
                          ];
                          description = ''
                            Patches from patch.yml to switch on, by name. Every
                            patch is off until it is named here.
                          '';
                        };
                      };
                    };
                  }
                )
              );
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
    modules = {
      gaming = {
        emulation = {
          rpcs3 = {
            # Currently only the two GTA V patches, relocated to the level
            # this host runs that game at. The file explains how, and how to
            # redo it. If another game ever needs the same, its definitions go
            # into this one file too, because the emulator reads no other.
            extraPatches = lib.mkDefault ./games/gta5/patch.yml;
            games = {
              # The games travel with the module, because everything about them
              # apart from where the dump sits is a property of the game and not
              # of a machine. The three values that DO belong to a dump are
              # overridable without mkForce: the location, and the binary hash
              # and disc revision the patches were written against, which differ
              # between regions and revisions of the same game.
              #
              # Every hash and version below was read out of patch.yml by the
              # serial of the dump on this host, which is the same lookup RPCS3
              # performs, and the enabled lists only ever name patches that
              # patch.yml really offers for that hash. A name that is not there
              # is silently ignored, so a typo looks exactly like a patch that
              # does nothing.
              uncharted2 = {
                source = lib.mkDefault "/mnt/raid/Games/U2";
                displayName = "Uncharted 2: Among Thieves™";
                serial = "BCES00757";
                icon = ./games/uncharted2/icon.png;
                customConfig = builtins.readFile ./games/uncharted2/config.yml;
                patch = {
                  title = "Uncharted 2: Among Thieves";
                  hash = lib.mkDefault "PPU-a3a5789c12711291dfe16a7d5d81c906d2b4c0c2";
                  version = lib.mkDefault "01.09";
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
                };
              };
              # The Game of the Year disc, which is BCES01670 and not the
              # BCES01175 of the original release. That matters twice: the per
              # title configuration is named after the serial, and a patch only
              # applies to the serial it is listed under.
              #
              # 01.19 is the level the update in Patches raises this serial to,
              # and it has to be an update ISSUED FOR THIS SERIAL. The
              # identically sized one for BCES01175 does not do it, RPCS3 looks
              # for an update under the serial it is booting and would install
              # that one beside the game rather than over it, leaving the disc
              # at the 01.10 it ships with.
              uncharted3 = {
                source = lib.mkDefault "/mnt/raid/Games/U3";
                displayName = "Uncharted 3: Drake's Deception™";
                serial = "BCES01670";
                icon = ./games/uncharted3/icon.png;
                customConfig = builtins.readFile ./games/uncharted3/config.yml;
                patch = {
                  title = "Uncharted 3: Drake's Deception";
                  hash = lib.mkDefault "PPU-02a88c3c6cd415b0bb81f1606bc743835881a4ba";
                  version = lib.mkDefault "01.19";
                  # The Uncharted 2 selection, minus the two names this game
                  # simply does not have, Disable SPU Post-processing and
                  # Disable Velocity Motion Blur, plus the two the copied
                  # settings ask for. Disable in-built MLAA is what makes
                  # Resolution Scale 150 work at all in this engine, and
                  # Performance (WCB) buys back what Write Color Buffers costs.
                  enabled = [
                    "Skip Intro"
                    "Unlock FPS"
                    "Disable Mesh Trimming"
                    "Enable GPU Lighting"
                    "Disable Depth of Field"
                    "Disable SSAO"
                    "Disable Motion Blur"
                    "Disable in-built MLAA"
                    "Performance (WCB)"
                  ];
                };
              };
              # The European disc at 01.11, the level the update in Patches
              # raises it to. The patches are declared for 01.11 and therefore
              # only bite once that update is installed, which the provisioning
              # service does on its own.
              tlou = {
                source = lib.mkDefault "/mnt/raid/Games/TLOU";
                displayName = "The Last of Us™";
                serial = "BCES01584";
                icon = ./games/tlou/icon.png;
                customConfig = builtins.readFile ./games/tlou/config.yml;
                patch = {
                  title = "The Last of Us";
                  hash = lib.mkDefault "PPU-120fb71f7352d62521c639b0e99f960018c10a56";
                  version = lib.mkDefault "01.11";
                  # The Uncharted 2 selection as far as it exists here, plus the
                  # two the copied settings ask for. Mind the lower case t in
                  # trimming, patch.yml spells this one differently from the
                  # Uncharted patches and the name is a key.
                  enabled = [
                    "Skip Intro"
                    "Unlock FPS"
                    "Disable Mesh trimming"
                    "Enable GPU Lighting"
                    "Disable Depth of Field"
                    "Disable SSAO"
                    "Disable Motion Blur"
                    "Disable in-built MLAA"
                    "WCB/WDB Performance fix"
                  ];
                };
              };
              # The European disc, BLES01807, run at 01.06, the oldest title
              # update Sony still serves for this serial. The update itself is
              # the pkg in Patches and the provisioning service installs it,
              # so nothing here has to name a level.
              #
              # This is the one game here whose patches do not come out of
              # patch.yml, and the hash below is why. That database knows this
              # serial at exactly two levels, the untouched disc at 01.00 and
              # the final update at 01.27. Patches are found by the hash of
              # the game binary, every title update produces a new binary, so
              # at 01.06 neither entry is ever consulted and both patches
              # would silently do nothing.
              #
              # What was missing at 01.06 was only the two addresses, so they
              # were relocated into the 01.06 binary and written down in
              # games/gta5/patch.yml. That file explains how, and how to redo
              # it for another level. The hash below is the one RPCS3 logs for
              # this binary and it is what ties the two together.
              #
              # "60 FPS" only does anything alongside Vblank Rate 120 in
              # games/gta5/config.yml. It does not unlock the limiter, it
              # points it at half the vblank rate, so the two belong together
              # and the note at that key says so from the other side.
              gta5 = {
                source = lib.mkDefault "/mnt/raid/Games/GTA5";
                displayName = "Grand Theft Auto V";
                serial = "BLES01807";
                icon = ./games/gta5/icon.png;
                customConfig = builtins.readFile ./games/gta5/config.yml;
                patch = {
                  # Spelled as the patch file spells it, brackets and all. It
                  # is a key there, so the plain title would match nothing and
                  # both patches would be ignored without a word of complaint.
                  title = "Grand Theft Auto V (Grand Theft Auto 5)";
                  hash = lib.mkDefault "PPU-918a2bb3b48af4dcf3b8c940318ac1a7e833791f";
                  version = lib.mkDefault "01.06";
                  # Both of them, which is the whole of what exists for this
                  # game. None of the names the Naughty Dog titles use are
                  # among them, so this list is short rather than trimmed.
                  enabled = [
                    "60 FPS"
                    "Skip Rockstar Boot Logo"
                  ];
                };
              };
            };
          };
        };
      };
    };
    systemd = {
      tmpfiles = {
        # Only what is under dev_hdd0 is RPCS3's own. A disc dump is reached
        # through a link with a stable name instead, so the boot path never
        # mentions the disk the dump happens to live on.
        rules = lib.mapAttrsToList (
          _: game: "L /home/${user}/Games/${game.link} - - - - ${game.source}"
        ) games;
      };
      services = {
        # Serves the one file described at u3-campaign-config above, on the
        # loopback address the Uncharted 3 swap list points that hostname at.
        # Port 80 is not a choice, the game builds the URL itself and never
        # names a port, so the stand-in has to sit where a default HTTP
        # request lands.
        #
        # This is a workaround for somebody else's misconfiguration and it
        # should not outlive it. If the backend ever gives that hostname a
        # server block, delete this service and the 127.0.0.1 entry in the
        # Uncharted 3 swap list together, and the game goes back to fetching
        # the file from them.
        rpcs3-u3-campaign-config = {
          description = "Local stand-in for the Uncharted 3 campaign config host";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          serviceConfig = {
            ExecStart = lib.concatStringsSep " " [
              (lib.getExe pkgs.darkhttpd)
              "${u3-campaign-config}"
              "--addr 127.0.0.1"
              "--port 80"
              "--no-listing"
            ];
            # Binding 80 is the only privilege this needs, so it gets that one
            # capability and nothing else, under a user that does not outlive
            # the unit.
            DynamicUser = true;
            AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
            CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
            NoNewPrivileges = true;
            PrivateTmp = true;
            PrivateDevices = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectControlGroups = true;
            RestrictAddressFamilies = [
              "AF_INET"
              "AF_INET6"
            ];
            RestrictNamespaces = true;
            SystemCallArchitectures = "native";
            MemoryDenyWriteExecute = true;
            Restart = "on-failure";
          };
        };
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
                    WantedBy = [ "default.target" ];
                  };
                };
              };
            };
          };
          xdg = {
            desktopEntries = gameDesktopEntries;
            configFile = gameCustomConfigs // extraPatchFile;
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
            ]
            ++ gamePackages;
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
              ".config/rpcs3/config.yml" = rpcs3File {
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
                    SPU loop detection: false
                    Max SPURS Threads: 6
                    SPU Block Size: Safe
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
                    Multithreaded RSX: false
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
                    Anisotropic Filter Override: 0
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
              # Welche Discs es gibt, siehe gameRegistry oben.
              ".config/rpcs3/games.yml" = rpcs3File {
                text = gameRegistry;
              };
              ".config/rpcs3/patches/patch.yml" = rpcs3File {
                source = ./patch.yml;
              };
              # Which of them are switched ON, see gamePatchConfig above.
              ".config/rpcs3/patch_config.yml" = rpcs3File {
                text = gamePatchConfig;
              };
              # The two directories below stay symlinked. rpcs3File copies a
              # single file, and these are whole trees that RPCS3 only reads.
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
              # SDL guesses a mapping for a pad it does not know, and for the
              # virtual one it now guesses right, because joymouse sends the
              # face buttons under the names SDL reads them by. The file writes
              # that same guess out, so nothing depends on a guess, and RPCS3
              # stops logging a warning that it is missing.
              #
              # It once corrected the guess instead of repeating it, back when
              # triangle arrived as square. That was fixed in joymouse itself.
              ".config/rpcs3/input_configs/gamecontrollerdb.txt" = rpcs3File {
                source = ./gamecontrollerdb.txt;
              };
              ".config/rpcs3/input_configs/active_input_configurations.yml" = rpcs3File {
                text = ''
                  Active Configurations:
                    global: Default
                '';
              };
              ".config/rpcs3/input_configs/global/Default.yml" = rpcs3File {
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
                      # square. RPCS3 computes
                      #
                      #   new_len = (1 + sin(2a)^2 / (factor / 1000)) * len
                      #
                      # and sin(2a) is zero on the axes and one on the
                      # diagonals, so this touches nothing but the corners.
                      #
                      # The walking stick needs it. JoyMouse gates the stick
                      # into a circle, which is right, but a circle only reaches
                      # 70.7 percent per axis on a diagonal, and a game that
                      # decides between walking and running from how far an axis
                      # is pushed never sees a full push while you hold two keys.
                      # This was set to zero and the character walked instead of
                      # running for exactly that reason.
                      #
                      # 2400 is the value at which a diagonal reaches the corner:
                      # (1 + 1/2.4) * cos(45) = 1.002, so it clamps to full.
                      # RPCS3's own default of 8000 only reaches 79.5 percent.
                      Left Pad Squircling Factor: 2400
                      # The aiming stick needs it too, and the reasoning that
                      # kept it at zero here was simply wrong. It claimed
                      # squircling bends the aim off the line the hand drew. It
                      # does not: RPCS3 works in polar coordinates and leaves
                      # the ANGLE untouched, only the radius grows.
                      #
                      # What it fixes is that a slanted flick travels less far
                      # than a straight one for the same hand movement. JoyMouse
                      # emits a perfect circle, the same magnitude in every
                      # direction, which is right. But a circle is 70.7 percent
                      # per axis on a diagonal, and a game that turns the camera
                      # from each axis through a curve of its own turns much
                      # less than that, about half. Aiming at anything off the
                      # horizontal fought back.
                      Right Pad Squircling Factor: 2400
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
