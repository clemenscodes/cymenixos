# Tools: was wofür und warum

Stand: Oktober 2026. Lizenzen wurden am 2026-10-01 direkt in den Repositories geprüft.
Für einen monetarisierten Kanal ist die Lizenz ein hartes Kriterium, deshalb steht sie
bei jeder Wahl dabei.

## Übersicht

| Aufgabe | Wahl | Lizenz | GPU |
|---|---|---|---|
| Skript, Recherche, Slide-Code | Strata (Qwen3.8-Flash-Next) | MIT | 5090 + 3080 |
| Bilder, Thumbnails | Qwen-Image 2.0 | Apache 2.0 | 5090 |
| Video, B-Roll | LTX-2.5, Zweitoption Wan 2.2 | LTX Community / Apache 2.0 | 5090, Wan 5B auch 3080 |
| Musik | ACE-Step 1.5 | MIT | 5090 oder 3080 |
| Stimme | Chatterbox Multilingual | MIT | 3080 |
| Slides | Revideo | MIT | CPU |
| Engine für Bild, Video, Musik | ComfyUI | GPL-3.0 | siehe [comfyui.md](comfyui.md) |
| Schnitt, Untertitel, Mix, Render | DaVinci Resolve Studio 21.1 | gekauft | 5090 |

## Skript: Strata

- **Warum:** läuft bereits, großes MoE-Modell lokal über 5090 + 3080 + RAM, OpenAI- und
  Anthropic-kompatible API auf Port 8090.
- **Alternativen:** llama.cpp oder ik_llama.cpp mit anderen MoE-Modellen. Lohnt erst,
  wenn ein anderes Modell klar besser schreibt.

## Bilder und Thumbnails: Qwen-Image 2.0

- **Warum:** beste Textdarstellung im Bild unter den offenen Modellen, und Titeltext ist
  bei Thumbnails die halbe Miete. Generieren und Editieren in einem 7B-Modell, native 2K,
  Apache 2.0. Ab 16 GB VRAM.
- **FLUX.2 [dev]:** beste Gesamtqualität, aber **FLUX Non-Commercial License**. Für einen
  monetarisierten Kanal nicht nutzbar.
- **FLUX.2 [klein] 4B:** Apache 2.0, klein und schnell, gute Zweitoption.
  **FLUX.2 [klein] 9B** ist dagegen wieder nicht-kommerziell.
- **SDXL:** riesiges Ökosystem, aber technisch überholt.

## Video: LTX-2.5, Zweitoption Wan 2.2

- **LTX-2.5:** das einzige offene Modell, das Bild und Ton in einem Durchgang erzeugt.
  ComfyUI-Integration direkt vom Hersteller, FP8-Variante für 32-GB-Karten.
  **Lizenz:** LTX-2.x Community License, kostenlos bis 10 Mio. US-Dollar Jahresumsatz,
  darüber kostenpflichtig (`LICENSE-2_x`, Abschnitt 2.1).
- **Wan 2.2:** Apache 2.0, sehr vielseitig, MoE-Architektur. Das 14B-Modell braucht etwa
  16 GB, die 5B-Variante läuft mit 8 GB und damit auf der 3080.
- **HunyuanVideo:** schwerer, ohne Vorteil für B-Roll.
- **Erwartung:** Minuten pro Clip von 5 bis 10 Sekunden. Für lange, zusammenhängende
  Einstellungen sind geschlossene Dienste weiter voraus. Für B-Roll, Übergänge und kurze
  Einspieler reicht es gut.

## Musik: ACE-Step 1.5

- **Warum:** MIT, schnell (laut Projekt unter 10 Sekunden pro Song auf einer 3090),
  nativ in ComfyUI. Ideal für Intro- und Hintergrundmusik.
- **YuE2:** stark bei Songs mit Gesang, aber deutlich langsamer.
- **Stable Audio:** eher Soundeffekte, restriktivere Lizenz.

## Stimme: Chatterbox Multilingual

- **Warum:** MIT, 23 Sprachen inklusive Deutsch, Voice Cloning aus 5 bis 10 Sekunden
  Referenz, Emotionssteuerung. Eigene Stimme klonen wirkt persönlicher und erlaubt, echte
  Aufnahmen unauffällig einzustreuen.
- **XTTS v2:** Coqui Public Model License, nicht-kommerziell.
- **Higgs Audio V3:** sehr gut, 100+ Sprachen, aber nicht-kommerziell.
- **Kokoro-82M:** winzig und schnell, aber kein Deutsch und kein Cloning.
- **VibeVoice:** lange Podcasts mit mehreren Sprechern, aber kein Cloning, Deutsch nicht
  offiziell. Ist als Modul bereits in cymenixos vorhanden.
- **Paketierung (D2, offen):** nicht in nixpkgs. Empfehlung: Nix-Paket auf derselben
  Python-Umgebung wie ComfyUI, damit PyTorch nur einmal gebaut wird.

## Slides: Revideo

- **Warum:** MIT, Slides und Animationen als TypeScript-Code, headless renderbar und
  synchron zur Audiospur. Ein LLM kann die Slides direkt aus dem Skript schreiben, und
  alles bleibt in Git.
- **Motion Canvas:** das Original, von dem Revideo abgeleitet ist. Hat einen Editor, aber
  keine Render-API für Automatisierung.
- **Remotion:** React, eigene Lizenz, für Firmen ab vier Personen kostenpflichtig.
- **Slidev:** für Präsentationen gebaut, nicht zeitgenau mit Audio.

## Schnitt: DaVinci Resolve Studio

- **Warum:** gekauft und installiert (21.1). Python-Scripting-API, offizielle
  Claude-Code-Integration seit 21.1, Transkription und animierte Untertitel, IntelliScript,
  Voice Isolation, AI Audio Assistant, H.264/H.265 über NVENC.
- **Linux-Einschränkung:** kein AAC-Import, auch in Studio nicht. Generierte Audiodateien
  sind ohnehin WAV, eigene Aufnahmen mit AAC vorher nach WAV wandeln. Generierte Clips
  als DNxHR oder ProRes übergeben, nicht als H.264.
- **Kdenlive:** freie Alternative, würde für Slides plus Stimme reichen.
- Details: [resolve.md](resolve.md).
