# KI-Content-Stack Implementierungsplan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ein lokaler, deklarativer Stack, der aus Notizen und eigenen Aufnahmen YouTube-Videos macht: Skript, Stimme, Slides, Bilder, B-Roll, Musik, Thumbnail und eine fertige Resolve-Timeline.

**Architecture:** Jede KI-Fähigkeit ist ein eigener systemd-Dienst aus einem cymenixos-Modul mit HTTP-API auf localhost. GPU-Belegung läuft über systemd-Targets, die sich gegenseitig ausschließen (`Conflicts=`), damit nie zwei Großverbraucher dieselbe Karte füllen. Ein separates Repo `channel/` orchestriert die Dienste pro Video und übergibt am Ende an DaVinci Resolve Studio über dessen Python-API.

**Tech Stack:** NixOS (cymenixos, amaru), Strata (LLM), ComfyUI 0.35 aus nixpkgs (Bild, Video, Musik), Chatterbox Multilingual (Stimme), Revideo (Slides), DaVinci Resolve Studio 21.1 (Schnitt, Untertitel, Render).

## Global Constraints

- Kein Geviertstrich (U+2014) in Code, Kommentaren, Commits. Deutsch mit echten Umlauten.
- Alle Modelle und Daten unter `/var/lib/ai/<dienst>`, persistiert über `modules.boot.impermanence.persistPath`, wie bei Strata.
- Alle Dienste lauschen nur auf `127.0.0.1`.
- Kein Dienst startet beim Boot (`autoStart = false`), Start und Stopp nur über die Modus-Targets.
- Die 3080 (`0000:03:00.0`) ist nur für Gruppe `gpu-compute` sichtbar und muss jederzeit an eine VM übergebbar bleiben.
- Jede Nix-Änderung ist erst fertig, wenn `nix build ...#nixosConfigurations.clemens.config.system.build.toplevel` mit `--override-input cymenixos path:/home/clemens/.local/src/cymenixos` durchläuft.
- Lizenzen: nur Modelle, die kommerzielle Nutzung erlauben (YouTube-Monetarisierung). Higgs Audio V3 ist deshalb ausgeschlossen.

---

## Komponentenübersicht

| Komponente | Zweck | Ort | Läuft als | GPU | Port | Phase |
|---|---|---|---|---|---|---|
| `vfio-gpu` + Hook | 3080 zwischen Host und VM umhängen | cymenixos `modules/virtualisation/virt-manager` | root | 3080 | - | 0 (gebaut) |
| Strata | Skript schreiben, Recherche, Slide-Code | cymenixos `modules/ai/strata` | `strata` | 5090 + 3080 | 8090 | 0 (gebaut) |
| Resolve Studio | Schnitt, Untertitel, Audio-Mix, Render | cymenixos `home-manager/.../davinci` | `clemens` | 5090 | - | 1 |
| ComfyUI | Qwen-Image, FLUX.2, LTX, Wan, ACE-Step | cymenixos `modules/ai/comfyui` (neu) | `comfyui` | 5090 | 8188 | 2 |
| Chatterbox | Deutsche Stimme, Voice Cloning | cymenixos `modules/ai/chatterbox` (neu) | `chatterbox` | 3080 | 8189 | 3 |
| Modus-Targets | `ai-script`, `ai-produce`, `ai-off` | cymenixos `modules/ai/modes` (neu) | systemd | beide | - | 4 |
| `channel` CLI | Pipeline pro Video | neues Repo `~/.local/src/channel` | `clemens` | - | - | 5 |
| Resolve-Bridge | Timeline aus `manifest.json` bauen, rendern | Repo `channel`, `resolve/` | `clemens` | - | - | 6 |

## Datenfluss

```
notes.md + eigene Aufnahmen
        │
        ▼
 [ai-script]  Strata :8090 ──► script.md ──► slides/*.tsx (Revideo)
        │
        ▼
 [ai-produce] Chatterbox :8189 ──► voice/*.wav           (3080)
              ComfyUI :8188    ──► images/*.png           (5090)
                               ──► broll/*.mov (DNxHR)
                               ──► music/*.wav (ACE-Step)
                               ──► thumbnail.png (Qwen-Image)
        │
        ▼
 Revideo-Render ──► slides/*.mov
        │
        ▼
 manifest.json ──► Resolve-Bridge ──► Resolve-Timeline ──► Feinschliff ──► H.265 NVENC ──► YouTube
```

## GPU-Modi

| Modus | 5090 | 3080 | Wann |
|---|---|---|---|
| `ai-script` | Strata (Hauptkarte) | Strata (Layer-Split) | Skript und Slides schreiben |
| `ai-produce` | ComfyUI | Chatterbox | Medien erzeugen |
| `ai-off` | Desktop, Resolve, Spiele | frei für VM | Schneiden, Spielen, VMs |

Ein Modus stoppt beim Start automatisch die Dienste der anderen (`Conflicts=`).

## Entscheidungen, die vor Phase 2 und 3 fallen müssen

- **D1 PyTorch mit CUDA, entschieden: lokal bauen.** Das ComfyUI-Paket zwingt `torch` 2.13.0 auf CUDA 13.3, diese Variante ist nicht im Cache (die gecachte nutzt CUDA 12.9, darunter schaltet ComfyUI seine optimierten Kernels ab). 36 Derivationen, mehrere Stunden, über Nacht. Begründung in `docs/ai-content-stack/comfyui.md`.
- **D2 Chatterbox-Paketierung:** nicht in nixpkgs. Empfehlung: Nix-Paket mit `buildPythonApplication` auf derselben `python`-Umgebung wie ComfyUI, damit Torch nur einmal gebaut wird. Die konkrete Aufgabenliste schreibt der Phase-3-Plan.
- **D3 Sprache des Kanals:** Deutsch, Englisch oder beides. Bestimmt die Stimmwahl (Chatterbox Multilingual für Deutsch, Kokoro wäre nur Englisch).

---

## Phase 0: GPU-Fundament abschließen

Der Code steht und ist aktiv (`vfio-gpu`, libvirt-Hook, udev-Seat-Regel, Strata mit `gpu = [0 1]`). Offen ist nur die Prüfung nach einem Reboot.

### Task 0.1: Reboot-Test der GPU-Übergabe

**Files:** keine Änderungen, nur Prüfung.

- [ ] **Step 1: Nach dem Reboot den Grundzustand prüfen**

Run:
```bash
sudo vfio-gpu status
nvidia-smi -L
sudo -u strata nvidia-smi -L
hyprctl monitors all | grep '^Monitor'
```
Expected: `0000:03:00.0: nvidia`, `0000:03:00.1: snd_hda_intel`, keine Prozesse gelistet. `clemens` sieht nur die 5090, `strata` sieht 5090 und 3080. Hyprland zeigt nur `DP-1`.

- [ ] **Step 2: VM-Start übergibt die Karte**

Run:
```bash
virsh -c qemu:///system start igris
sleep 5
sudo vfio-gpu status
```
Expected: beide Funktionen auf `vfio-pci`.

- [ ] **Step 3: VM-Stop gibt die Karte zurück**

Run:
```bash
virsh -c qemu:///system destroy igris
sleep 5
sudo vfio-gpu status
sudo -u strata nvidia-smi -L
```
Expected: `nvidia` und `snd_hda_intel`, `strata` sieht wieder beide Karten.

- [ ] **Step 4: Belegte Karte blockiert den VM-Start sauber**

Run:
```bash
systemctl start strata
virsh -c qemu:///system start igris; echo "exit=$?"
systemctl stop strata
```
Expected: `exit=1`, die Fehlermeldung nennt den Strata-Prozess, kein hängender Prozess, `vfio-gpu status` zeigt weiter `nvidia`.

- [ ] **Step 5: Strata Layer-Split gegen 5090 allein messen**

Run:
```bash
systemctl start strata
journalctl -u strata -f | grep -m1 'layer split'
```
Expected: eine Zeile `layer split: layers 0-K (CUDA0), K+1-47 (CUDA1)`. Dann im Web-UI unter `http://127.0.0.1:8090` denselben Prompt dreimal ausführen und tok/s notieren. Danach `gpu = 0` in `amaru/configuration.nix` setzen, `nixos-rebuild switch`, gleiche Messung. Die schnellere Variante bleibt.

### Task 0.2: Commit und amaru-Bump (erledigt am 2026-10-01, cymenixos `670af04f`)

**Files:**
- Commit: `cymenixos/modules/virtualisation/virt-manager/default.nix`, `cymenixos/modules/ai/strata/default.nix`
- Modify: `amaru/configuration.nix` (schon geändert), `amaru/flake.lock`

- [ ] **Step 1: cymenixos committen**

```bash
cd ~/.local/src/cymenixos
git add modules/virtualisation/virt-manager/default.nix modules/ai/strata/default.nix
git commit -m "vfio: keep the passthrough gpu on the host until a vm takes it

strata: run on several gpus in a layer split"
```

- [ ] **Step 2: Pushen, amaru bumpen, bauen, committen**

```bash
cd ~/.local/src/cymenixos && git push
cd ~/.local/src/amaru && nix flake update cymenixos
sudo nixos-rebuild switch --flake .#clemens
git add configuration.nix flake.lock
git commit -m "bump cymenixos, strata on both gpus"
```
Expected: Build ohne `--override-input` erfolgreich.

---

## Phase 1: Resolve Studio dauerhaft aktivieren

Erledigt am 2026-10-01 bis auf den Reboot-Test (Step 4). Die Lizenz lässt sich nicht deklarativ bereitstellen, weil RLM kopierte Dateien ablehnt; Hintergrund und Neuaktivierung in `docs/ai-content-stack/resolve.md`. Die Schritte unten bleiben als Ablauf für eine Neuaktivierung.

### Task 1.1: Persistenz aktivieren und Lizenz eintragen

**Files:**
- Modify: `cymenixos/modules/home-manager/modules/media/editing/davinci/default.nix` (schon geändert)

- [ ] **Step 1: Resolve beenden, dann umschalten**

```bash
pgrep -f davinci-resolve-studio && echo "erst Resolve beenden"
cd ~/.local/src/amaru
sudo nixos-rebuild switch --flake .#clemens --override-input cymenixos path:/home/clemens/.local/src/cymenixos
findmnt -T ~/.local/share/DaVinciResolve -o TARGET,SOURCE
```
Expected: `SOURCE` zeigt einen Pfad unter `/persist`.

- [ ] **Step 2: Lizenz einmal eingeben**

Resolve starten, „Lizenzschlüssel verwenden“, Key aus Bitwarden einfügen. Danach:
```bash
ls ~/.local/share/DaVinciResolve/license
```
Expected: mindestens eine Lizenzdatei.

- [ ] **Step 3: Externe Skripte erlauben**

In Resolve: Einstellungen, System, Allgemein, „Externe Skripterstellung verwenden“ auf **Lokal**. Nötig für Phase 6.

- [ ] **Step 4: Nach dem nächsten Reboot prüfen**

Expected: Resolve startet ohne Lizenzdialog.

- [ ] **Step 5: Commit**

```bash
cd ~/.local/src/cymenixos
git add modules/home-manager/modules/media/editing/davinci/default.nix
git commit -m "davinci: persist the resolve data, the studio activation lives there"
```

---

## Phase 2: ComfyUI-Dienst

Voraussetzung: D1 entschieden.

### Task 2.1: Modul `modules/ai/comfyui`

**Files:**
- Create: `cymenixos/modules/ai/comfyui/default.nix`
- Modify: `cymenixos/modules/ai/default.nix` (Import ergänzen, wie bei `./strata`)
- Modify: `amaru/configuration.nix` (unter `modules.ai`)

**Interfaces:**
- Produces: `modules.ai.comfyui.{enable, gpu, port, dataDir, models}`, Dienst `comfyui.service`, HTTP-API `http://127.0.0.1:8188` (`/system_stats`, `/prompt`, `/history/<id>`, `/view`).

- [ ] **Step 1: Prüfen, wie `modules/ai/default.nix` Module einbindet**

Run: `grep -n "strata" ~/.local/src/cymenixos/modules/ai/default.nix`
Expected: eine Zeile `(import ./strata {inherit inputs pkgs lib;})`. Genau so wird `./comfyui` ergänzt.

- [ ] **Step 2: Modul schreiben**

```nix
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
  cfg = config.modules.ai;
  inherit (config.modules.boot.impermanence) persistPath;

  cudaPkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      cudaSupport = true;
      allowUnfree = true;
    };
  };

  dataDir = cfg.comfyui.dataDir;

  # lädt die Modelle aus der Config, jedes einmal, abgebrochene Downloads laufen weiter
  models = pkgs.writeShellApplication {
    name = "comfyui-models";
    runtimeInputs = [pkgs.curl pkgs.coreutils];
    text = lib.concatStrings (lib.mapAttrsToList (name: m: ''
        mkdir -p ${dataDir}/models/${m.dir}
        f=${dataDir}/models/${m.dir}/${name}
        if [ ! -e "$f" ]; then
          echo "downloading ${name} ..."
          curl -fL --retry 10 --retry-all-errors -C - -o "$f.part" ${lib.escapeShellArg m.url}
          mv "$f.part" "$f"
        fi
      '')
      cfg.comfyui.models);
  };
in {
  options = {
    modules = {
      ai = {
        comfyui = {
          enable = lib.mkEnableOption "Enable ComfyUI for image, video and music generation";
          gpu = lib.mkOption {
            type = lib.types.int;
            default = 0;
            description = "GPU to run on, as nvidia-smi numbers them";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 8188;
            description = "Port of the web UI and the API";
          };
          dataDir = lib.mkOption {
            type = lib.types.str;
            default = "/var/lib/ai/comfyui";
            description = "Models, custom nodes, inputs and outputs";
          };
          models = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule {
              options = {
                url = lib.mkOption {
                  type = lib.types.str;
                  description = "Download URL of the model file";
                };
                dir = lib.mkOption {
                  type = lib.types.str;
                  description = "Folder below models/, such as diffusion_models, text_encoders or vae";
                };
              };
            });
            default = {};
            description = "Model files by file name, downloaded once before ComfyUI starts";
          };
        };
      };
    };
  };

  config = lib.mkIf (cfg.enable && cfg.comfyui.enable) {
    environment = {
      persistence = lib.mkIf config.modules.boot.enable {
        "${persistPath}" = {
          directories = [dataDir];
        };
      };
    };

    services = {
      comfyui = {
        enable = true;
        package = cudaPkgs.comfyui;
        inherit dataDir;
        listen = ["127.0.0.1"];
        inherit (cfg.comfyui) port;
        extraArgs = ["--cuda-device=${toString cfg.comfyui.gpu}"];
      };
    };

    systemd = {
      tmpfiles = {
        rules = ["d ${dataDir} 0750 comfyui comfyui -"];
      };
      services = {
        comfyui-models = {
          description = "ComfyUI: download the models";
          after = ["network-online.target"];
          wants = ["network-online.target"];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            User = "comfyui";
            ExecStart = lib.getExe models;
            TimeoutStartSec = "infinity";
          };
        };
        comfyui = {
          # nur über die Modus-Targets, nie beim Boot
          wantedBy = lib.mkForce [];
          requires = ["comfyui-models.service"];
          after = ["comfyui-models.service"];
          environment = {
            CUDA_DEVICE_ORDER = "PCI_BUS_ID";
          };
          serviceConfig = {
            # gpu-compute öffnet die 3080, falls gpu = 1
            SupplementaryGroups = lib.optional (config.users.groups ? gpu-compute) "gpu-compute";
          };
        };
      };
    };
  };
}
```

- [ ] **Step 3: In amaru aktivieren, ohne Modelle**

In `amaru/configuration.nix` unter `modules.ai`:
```nix
      comfyui = {
        enable = true;
      };
```

- [ ] **Step 4: Bauen** (D1: dauert beim ersten Mal Stunden)

Run:
```bash
cd ~/.local/src/amaru
nix build --no-link --override-input cymenixos path:/home/clemens/.local/src/cymenixos \
  .#nixosConfigurations.clemens.config.system.build.toplevel
```
Expected: endet mit einem Store-Pfad `nixos-system-amaru-...`.

- [ ] **Step 5: Umschalten und API prüfen**

```bash
sudo nixos-rebuild switch --flake .#clemens --override-input cymenixos path:/home/clemens/.local/src/cymenixos
sudo systemctl start comfyui
sleep 20
curl -s http://127.0.0.1:8188/system_stats | nix run nixpkgs#jq -- '.devices[].name'
```
Expected: genau ein Gerät, `"cuda:0 NVIDIA GeForce RTX 5090 : cudaMallocAsync"`.

- [ ] **Step 6: Gegenprobe 3080 unter der Härtung des Dienstes**

Der nixpkgs-Dienst läuft mit `PrivateUsers=true`. Prüfen, dass die Gruppe `gpu-compute` trotzdem greift:
```bash
sudo systemd-run --wait --pipe -p User=comfyui -p PrivateUsers=yes \
  -p SupplementaryGroups=gpu-compute -p Environment=CUDA_DEVICE_ORDER=PCI_BUS_ID \
  nvidia-smi -L
```
Expected: 5090 und 3080 gelistet. Falls nur die 5090 erscheint, bekommt `systemd.services.comfyui.serviceConfig` zusätzlich `PrivateUsers = lib.mkForce false;`, dann Step 6 wiederholen.

- [ ] **Step 7: Commit**

```bash
cd ~/.local/src/cymenixos
git add modules/ai/comfyui/default.nix modules/ai/default.nix
git commit -m "ai: add a comfyui module for image, video and music generation"
```

### Task 2.2: Modelle deklarieren

**Files:**
- Modify: `amaru/configuration.nix` (`modules.ai.comfyui.models`)

- [ ] **Step 1: Exakte Dateien bei Hugging Face nachschlagen**

Für jedes Modell die Dateiliste abrufen, zum Beispiel:
```bash
curl -s https://huggingface.co/api/models/Comfy-Org/Qwen-Image_ComfyUI | nix run nixpkgs#jq -- -r '.siblings[].rfilename'
```
Gesucht, jeweils in der Comfy-Org-Repackage-Variante, damit die Ordnerstruktur zu ComfyUI passt:
- Qwen-Image 2.0 (Diffusion-Modell, Text-Encoder, VAE)
- LTX-2.3 oder LTX-2.5 FP8
- Wan 2.2 TI2V 5B
- ACE-Step 1.5

- [ ] **Step 2: In amaru eintragen**

Schema pro Datei:
```nix
        models = {
          "<dateiname>.safetensors" = {
            url = "https://huggingface.co/<repo>/resolve/main/<pfad>/<dateiname>.safetensors";
            dir = "diffusion_models";
          };
        };
```

- [ ] **Step 3: Download und Smoke-Test**

```bash
sudo nixos-rebuild switch --flake .#clemens --override-input cymenixos path:/home/clemens/.local/src/cymenixos
sudo systemctl restart comfyui-models comfyui
journalctl -u comfyui-models -f
```
Dann im Browser `http://127.0.0.1:8188` die mitgelieferte Qwen-Image-Vorlage öffnen und ein Bild erzeugen.
Expected: Bild unter `/var/lib/ai/comfyui/output/`.

- [ ] **Step 4: Workflows als API-JSON exportieren**

Für Qwen-Image, LTX und ACE-Step jeweils „Export (API)“. Die Dateien landen in Phase 5 in `channel/workflows/`.

- [ ] **Step 5: Commit in amaru**

```bash
cd ~/.local/src/amaru
git add configuration.nix
git commit -m "comfyui: qwen-image, ltx, wan and ace-step models"
```

---

## Phase 3: Stimme (Chatterbox Multilingual auf der 3080)

Eigener Plan, sobald D2 und D3 entschieden sind. Fester Rahmen:
- Modul `modules/ai/chatterbox`, Nutzer `chatterbox` in `gpu-compute`, `CUDA_VISIBLE_DEVICES` auf die 3080, Port 8189.
- API: `POST /v1/audio/speech` mit `{ "input", "voice", "language" }`, Antwort WAV. Dieselbe Form wie die OpenAI-Speech-API, damit `channel` den Anbieter tauschen kann.
- Referenzstimmen unter `/var/lib/ai/chatterbox/voices/<name>.wav`, deine eigene Stimme als 10-30 s saubere Aufnahme.
- Abnahme: 60 s deutscher Text in unter 60 s Rechenzeit, Stimme klingt nach der Referenz.

## Phase 4: GPU-Modi

Eigener Plan nach Phase 3. Fester Rahmen:
- `ai-script.target` will `strata.service`, `Conflicts=ai-produce.target`.
- `ai-produce.target` will `comfyui.service` und `chatterbox.service`, `Conflicts=ai-script.target`.
- `ai-off`: beide Targets stoppen.
- Befehl `ai-mode script|produce|off` für deinen User ohne sudo, per polkit-Regel wie bei Strata.
- `vfio-gpu guest` bleibt dabei unverändert: Hält ein Dienst die 3080, nennt der VM-Start ihn.

## Phase 5: Repo `channel`

Eigener Plan nach Phase 4. Fester Rahmen:

```
channel/
  flake.nix              devShell: python3 (httpx, pydantic), node (revideo), ffmpeg
  workflows/             ComfyUI-API-JSON aus Task 2.2
  channel/               Python-Paket, ein Modul pro Schritt
    strata.py            OpenAI-kompatibler Client gegen :8090
    comfy.py             /prompt, /history, /view gegen :8188
    voice.py             /v1/audio/speech gegen :8189
    manifest.py          manifest.json lesen und schreiben
  videos/<slug>/
    notes.md             deine Inputs
    script.md            generiert, von dir redigiert
    slides/              Revideo-Projekt
    assets/              voice/, images/, broll/, music/, own/
    thumbnail.png
    manifest.json        Reihenfolge, Dauer, Dateien pro Abschnitt
```

Befehle: `channel new <slug>`, `channel script`, `channel voice`, `channel visuals`, `channel music`, `channel thumb`, `channel slides`, `channel timeline`. Jeder Schritt überspringt fertige Dateien, so dass du an jeder Stelle eingreifen und neu starten kannst.

## Phase 6: Resolve-Bridge

Eigener Plan nach Phase 5. Fester Rahmen:
- Skript `channel/resolve/build_timeline.py` gegen `DaVinciResolveScript` (in der Resolve-Installation unter `Developer/Scripting/Modules`), ausgeführt in der Resolve-Konsole oder extern mit „Externe Skripterstellung: Lokal“.
- Liest `manifest.json`, importiert alle Assets in einen Bin pro Video, legt Videospur 1 (Slides, B-Roll, eigene Clips), Audiospur 1 (Stimme), Audiospur 2 (Musik) an.
- Render-Preset „YouTube H.265 NVENC 2160p“. Generierte Audiodateien sind WAV, eigene Aufnahmen mit AAC werden vorher mit ffmpeg nach WAV gewandelt, weil Resolve unter Linux kein AAC dekodiert.
- Untertitel, Voice Isolation und Ducking macht Resolve selbst.

---

## Selbstprüfung

- Jede Komponente aus der Übersicht hat eine Phase: vfio-gpu und Strata (0), Resolve (1, 6), ComfyUI (2), Chatterbox (3), Modi (4), channel (5).
- Phasen 3 bis 6 sind bewusst als Rahmen geschrieben. Ihre Schnittstellen hängen an D2, D3 und an den exportierten Workflows aus Task 2.2. Jede bekommt vor dem Start einen eigenen Plan im selben Ordner.
