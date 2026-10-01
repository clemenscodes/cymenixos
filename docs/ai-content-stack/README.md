# Lokaler KI-Content-Stack

Ein lokaler, deklarativer Stack auf NixOS, der aus Notizen und eigenen Aufnahmen
YouTube-Videos macht: Skript, Stimme, Slides, Bilder, B-Roll, Musik, Thumbnail und eine
fertige Timeline in DaVinci Resolve Studio.

## Dokumente

| Dokument | Inhalt |
|---|---|
| [tools.md](tools.md) | Welches Tool wofür, warum, Alternativen, Lizenzen |
| [comfyui.md](comfyui.md) | Was ComfyUI ist, warum es die Basis ist, PyTorch- und CUDA-Entscheidung |
| [gpus.md](gpus.md) | Wie 5090 und 3080 zwischen Desktop, KI-Diensten und VMs geteilt werden |
| [resolve.md](resolve.md) | Resolve Studio unter NixOS mit Impermanence, Lizenz, Scripting |
| [references.md](references.md) | Alle Doku-Links und lokalen Doku-Pfade |
| [../superpowers/plans/2026-10-01-ai-content-stack.md](../superpowers/plans/2026-10-01-ai-content-stack.md) | Umsetzungsplan in Phasen |

## Hardware

| Teil | Rolle |
|---|---|
| RTX 5090, 32 GB, `0000:01:00.0` | Desktop, Resolve, Spiele, ComfyUI, Strata-Hauptkarte |
| RTX 3080, 10 GB, `0000:03:00.0` | Strata-Zweitkarte, Stimme, oder VM-Passthrough |
| Ryzen 9 9950X3D, 96 GB DDR5 | Strata-Experten im RAM, CPU-Pool |

## Komponenten

| Komponente | Zweck | Ort | Läuft als | GPU | Port | Stand |
|---|---|---|---|---|---|---|
| `vfio-gpu` + libvirt-Hook | 3080 zwischen Host und VM umhängen | cymenixos `modules/virtualisation/virt-manager` | root | 3080 | - | aktiv |
| Strata | Skript, Recherche, Slide-Code | cymenixos `modules/ai/strata` | `strata` | 5090 + 3080 | 8090 | aktiv |
| Resolve Studio 21.1 | Schnitt, Untertitel, Audio, Render | cymenixos `modules/home-manager/modules/media/editing/davinci` | `clemens` | 5090 | - | aktiv |
| ComfyUI | Bild, Video, Musik | cymenixos `modules/ai/comfyui` | `comfyui` | 5090 | 8188 | geplant |
| Chatterbox | Stimme | cymenixos `modules/ai/chatterbox` | `chatterbox` | 3080 | 8189 | geplant |
| Modus-Targets | GPU-Belegung umschalten | cymenixos `modules/ai/modes` | systemd | beide | - | geplant |
| `channel` | Pipeline pro Video | Repo `~/.local/src/channel` | `clemens` | - | - | geplant |

## Datenfluss

```
notes.md + eigene Aufnahmen
        │
        ▼
 [ai-script]  Strata :8090 ──► script.md ──► slides/ (Revideo)
        │
        ▼
 [ai-produce] Chatterbox :8189 ──► voice/*.wav           (3080)
              ComfyUI :8188    ──► images/*.png           (5090)
                               ──► broll/*.mov
                               ──► music/*.wav
                               ──► thumbnail.png
        │
        ▼
 Revideo-Render ──► slides/*.mov
        │
        ▼
 manifest.json ──► Resolve-Bridge ──► Timeline ──► Feinschliff ──► H.265 NVENC ──► YouTube
```

## Grundsätze

- Alles läuft lokal, alle Dienste lauschen nur auf `127.0.0.1`.
- Kein Dienst startet beim Boot. GPU-Großverbraucher werden über Modi gestartet, die
  sich gegenseitig ausschließen.
- Nur Modelle mit Lizenzen, die kommerzielle Nutzung erlauben (Monetarisierung).
- Eigene Inputs (Meinung, Erfahrung, Code, Aufnahmen) sind Pflicht. YouTube verlangt
  die Kennzeichnung realistischer KI-Inhalte, und reine Massenproduktion fällt unter
  die Richtlinie zu nicht authentischen Inhalten.

## Offene Entscheidungen

| | Frage | Stand |
|---|---|---|
| D1 | PyTorch mit CUDA 13 lokal bauen | entschieden: ja, siehe [comfyui.md](comfyui.md) |
| D2 | Wie Chatterbox paketiert wird | offen, Empfehlung in [tools.md](tools.md) |
| D3 | Sprache des Kanals: Deutsch, Englisch oder beides | offen |
