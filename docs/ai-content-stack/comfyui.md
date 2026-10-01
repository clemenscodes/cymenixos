# ComfyUI

## Was es ist

ComfyUI ist eine Engine für generative Modelle (Bild, Video, Audio) mit einer
Node-Oberfläche. Statt Formularfeldern baut man einen Graphen aus Bausteinen:
Modell laden, Text kodieren, Sampler, dekodieren, speichern.

Für diesen Stack zählt:

- **Workflows sind JSON-Dateien.** Sie lassen sich in Git versionieren, wiederholen und
  diffen.
- **HTTP-API:** einen Workflow im API-Format an `POST /prompt` schicken, über
  `GET /history/<id>` den Status abfragen, Ergebnisse über `GET /view` holen.
  `GET /system_stats` zeigt Geräte und VRAM.
- **Eine Engine für alles:** Qwen-Image, Wan, LTX und ACE-Step werden nativ unterstützt,
  ohne Custom Nodes.
- **Speicherverwaltung:** lädt und entlädt Modelle selbst und lagert bei Bedarf in den
  RAM aus.

## Warum ComfyUI und nicht ...

| Tool | Stärke | Warum nicht als Basis |
|---|---|---|
| Forge / Automatic1111 | einfache Formular-Oberfläche | fast nur Bilder, neue Modelle kommen spät, A1111 stagniert |
| InvokeAI | Leinwand zum manuellen Bearbeiten | weniger Modelle, schwächer bei Automatisierung |
| SwarmUI | freundliche Oberfläche | nutzt intern selbst ComfyUI |
| diffusers | volle Kontrolle im Code | pro Modell eigener Code, kein visuelles Ausprobieren |

## Grenzen und Regeln

- Steile Lernkurve am Anfang.
- **Keine Custom Nodes.** Sie sind beliebiger Python-Code von Dritten, ein
  Sicherheitsrisiko und unter Nix mühsam zu paketieren. Die eingebauten Nodes reichen für
  alle geplanten Modelle.
- Ein ComfyUI-Prozess nutzt genau eine GPU (`--cuda-device`).

## Paket und Dienst

- nixpkgs liefert `comfyui` 0.35.0 und das NixOS-Modul `services.comfyui`
  (`nixos/modules/services/misc/comfyui.nix`).
- Optionen des Moduls: `enable`, `package`, `dataDir`, `listen`, `port`, `extraArgs`.
  Das Modul setzt selbst `--base-directory`, `--database-url`, `--listen`, `--port`.
- Der Dienst läuft als `comfyui` mit starker systemd-Härtung, unter anderem
  `PrivateUsers=true`. Ob die Gruppe `gpu-compute` darunter greift, ist in Phase 2 zu
  prüfen (Plan, Task 2.1, Step 6).

## PyTorch und CUDA (D1, entschieden)

Geprüft am 2026-10-01 gegen die gepinnte nixpkgs-Revision:

| | PyTorch | CUDA | Im Binary-Cache |
|---|---|---|---|
| Standard-`torch` mit `cudaSupport` | 2.13.0 | 12.9 | ja, `cache.nixos-cuda.org` |
| `torch` im ComfyUI-Paket | 2.13.0 | 13.3 | nein, weder dort noch `cache.nixos.org` |

Das ComfyUI-Paket in nixpkgs überschreibt `torch` und `triton` absichtlich auf
`cudaPackages_13`. Grund im ComfyUI-Code, `comfy/quant_ops.py`: Unter CUDA 13 schaltet
ComfyUI seine optimierten CUDA-Kernels („comfy-kitchen“) für quantisierte Modelle ab und
warnt „You need pytorch with cu130 or higher to use optimized CUDA operations“.
Betroffen sind gerade die FP8- und NVFP4-Modelle, die auf der 5090 am meisten bringen.

**Entscheidung:** die CUDA-13-Variante einmal lokal bauen. Laut Dry-Run sind das
36 Derivationen, darunter `torch`, `torchvision`, `torchaudio`. Rechenzeit mehrere
Stunden, am besten über Nacht. Danach liegt alles im Store, bis sich nixpkgs bewegt.

Prüfen, was gebaut werden müsste:

```bash
nix build --dry-run --impure --expr \
  'let pkgs = import <nixpkgs> { config = { cudaSupport = true; allowUnfree = true; }; }; in pkgs.comfyui'
```

## Geplantes Modul

`modules/ai/comfyui` in cymenixos, Details im Plan (Phase 2):
Datenverzeichnis `/var/lib/ai/comfyui` (persistiert), nur `127.0.0.1:8188`,
`--cuda-device=0`, Modelle deklarativ als `models.<datei> = { url; dir; }` mit einem
vorgeschalteten Download-Dienst, kein Start beim Boot.
