# DaVinci Resolve Studio

## Installation

cymenixos `modules/home-manager/modules/media/editing/davinci`, aktiviert über
`modules.media.editing.davinci = { enable = true; studio = true; }`. Resolve läuft in
einer bwrap-Sandbox. Der Lizenzordner wird von
`~/.local/share/DaVinciResolve/license` auf `<store>/.license` gebunden, `Extras`
ebenso.

## Persistenz

Das Modul persistiert `~/.local/share/DaVinciResolve` über impermanence. Dort liegen:

- `license/`: die Studio-Aktivierung
- `Resolve Disk Database/`: die Projektdatenbank
- `configs/`, `Fusion/`, `Extras/`: Einstellungen und nachgeladene Pakete

Ohne Persistenz wären Aktivierung und Projekte nach jedem Reboot weg.

## Lizenz: warum nicht deklarativ

Resolve nimmt den Key aus keiner Datei, keiner Kommandozeilen-Option und keiner
Umgebungsvariable entgegen. Er wird im Dialog eingegeben und online gegen Blackmagic
aktiviert. Dabei entsteht ein RLM-Lizenzspeicher (Reprise License Manager) mit etwa
400 Dateien unter `license/blackmagic/.../Do-NOT-Touch-Anything-in-This-RLM-Directory`.

**RLM lehnt kopierte oder wiederhergestellte Dateien ab, auch byte-identische.**
Nachgewiesen am 2026-10-01:

1. Aktivierung auf dem flüchtigen Root, dann per `cp -a` nach `/persist` kopiert:
   Lizenzdialog.
2. Aus einem sops-verschlüsselten Tar wiederhergestellt: Lizenzdialog.
3. Gegenprobe mit den Originaldateien (gleicher Inhalt, Original-Inodes) per Bind-Mount:
   läuft als Studio.

Deshalb scheidet jede Bereitstellung aus sops, Tar oder Backup aus. Die Aktivierung muss
direkt auf dem persistenten Volume entstehen und wird dann nur noch persistiert.

### Neu aktivieren, etwa nach Neuaufsetzen von `/persist`

1. Resolve beenden.
2. Prüfen, dass `~/.local/share/DaVinciResolve` auf `/persist` liegt:
   `findmnt -T ~/.local/share/DaVinciResolve -o SOURCE`
3. Resolve starten, Key aus Bitwarden eingeben.
4. Prüfen: `stat -c %i` auf `~/.local/share/DaVinciResolve/license/.davinciresolvestudio_14.0.lic`
   und auf denselben Pfad unter `/persist/home/clemens/...` liefert dieselbe Inode.

Laut Blackmagic rotiert die Lizenz bei einer neuen Aktivierung auf die zuletzt
aktivierten zwei Maschinen. Vorheriges Deaktivieren ist nicht nötig.

### Bekanntes Verhalten

Nach „Beenden“ im Lizenzdialog kann der Resolve-Prozess hängen bleiben und SIGTERM
ignorieren. Dann `kill -KILL`, solange kein Projekt offen ist.

## Linux-Besonderheiten

- H.264 und H.265 über NVENC exportieren geht mit Studio.
- Kein AAC-Import, auch nicht in Studio. Eigene Aufnahmen vorher nach WAV wandeln, etwa
  `ffmpeg -i in.mp4 -c:v copy -c:a pcm_s16le out.mov`.
- Generierte Clips als DNxHR oder ProRes übergeben.
- Resolve sieht nur die 5090 (die 3080 ist für `clemens` gesperrt). Läuft Strata, ist die
  5090 voll, deshalb zum Schneiden Strata stoppen.

## Scripting

- Lokale Doku im Paket: `<store>/Developer/Scripting/README.md`, Typen in
  `DaVinciResolveScript.pyi`, Beispiele in `Examples/`. Aktueller Pfad:
  `/nix/store/2765nr3hl1vrdi8pnicmwqmqd5zz07cn-davinci-resolve-studio-21.1/Developer/Scripting/`.
  Er ändert sich mit jedem Resolve-Update.
- Externe Skripte erfordern in Resolve: Einstellungen, System, Allgemein,
  „Externe Skripterstellung verwenden“ auf **Lokal**.
- 21.1 bringt 20 neue Scripting-APIs, eine eingebaute Konsole und eine offizielle
  Integration mit Claude Code. Es gibt einen MCP-Server, siehe [references.md](references.md).
