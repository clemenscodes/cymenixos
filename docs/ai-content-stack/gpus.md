# GPU-Aufteilung

## Ziel

Die 3080 gehört standardmäßig dem Host und ist dort für KI-Dienste nutzbar. Startet eine
VM mit GPU-Passthrough, wechselt sie automatisch an `vfio-pci` und danach wieder zurück.

## Bausteine (cymenixos `modules/virtualisation/virt-manager`)

| Baustein | Was er tut |
|---|---|
| Option `vfio.devices` | PCI-Funktionen der Passthrough-Karte, Videofunktion zuerst. Standard `0000:03:00.0`, `0000:03:00.1` |
| Keine Boot-Bindung | `vfio-pci ids=` ist entfernt, die Karte bootet auf `nvidia` und `snd_hda_intel` |
| udev-Regel `72-vfio-gpu.rules` | legt die DRM-Nodes der Karte auf den Seat `seat-vfio`, nimmt `master-of-seat` und `uaccess` weg, Gruppe `gpu-compute`, Modus 0660. Legt nach dem Binden an `nvidia` `/dev/nvidiaN` an |
| Gruppe `gpu-compute` | nur ihre Mitglieder öffnen die 3080, zurzeit `strata` |
| `vfio-gpu` | `status`, `guest [--no-return]`, `host`, `nodes` |
| libvirt-Hook `qemu.d/vfio-gpu` | `prepare/begin`: `vfio-gpu guest --no-return`, `release/end`: `vfio-gpu host`. Nur für Domains, deren `<hostdev><source>` die Karte nennt |

## Warum so

- **Hyprland greift sonst zu.** Eine nachträglich gebundene GPU übernimmt aquamarine bei
  Hotplug ohne Seat-Prüfung und ohne `AQ_DRM_DEVICES`. logind verweigert aber Geräte
  fremder Seats (`session_device_verify`: `EPERM`). Der eigene Seat hält den Compositor
  zuverlässig fern.
- **Desktop-Programme greifen sonst zu.** Im Test hat jede neue GL-App die 3080 mit
  geöffnet, sogar ein frisches Kitty. Das hätte jeden VM-Start blockiert. Mit Rechten
  0660 und Gruppe `gpu-compute` überspringt der NVIDIA-Treiber die Karte sauber. Vulkan
  listet sie noch, Spiele wählen die 5090.
- **Ein belegter Treiber hängt den Kernel.** Ein nvidia-Unbind, während ein Prozess die
  Karte offen hat, blockiert dauerhaft. `vfio-gpu guest` prüft deshalb vorher
  `/dev/nvidiaN` und `renderD*` und bricht mit einer Prozessliste ab.
- **NixOS legt `/dev/nvidiaN` nur beim Laden des Moduls an.** Für eine später gebundene
  Karte übernimmt das `vfio-gpu nodes`.

## Bedienung

```bash
sudo vfio-gpu status           # wer hat die Karte
sudo vfio-gpu guest            # an vfio-pci, kommt automatisch zurück, wenn qemu sie loslässt
sudo vfio-gpu host             # zurück an den Host
sudo -u strata nvidia-smi -L   # was ein gpu-compute-Mitglied sieht
```

- **libvirt-VMs** (distroLab, Windows): nichts zu tun, der Hook macht alles.
- **vanix:** übergibt die Karte nicht selbst. Vor `vanix up` einmal
  `sudo vfio-gpu guest`. Die Karte geht zurück, sobald qemu sie eine Minute lang nicht
  hält. Eine Integration in vanix bräuchte dort eine ADR, siehe vanix `CLAUDE.md`.
- **Belegt ein Dienst die 3080**, etwa Strata, schlägt der VM-Start mit Prozessliste fehl.
  Vorher `systemctl stop strata`.

## Strata auf beiden Karten

- `modules.ai.strata.gpu = [0 1]` (5090 als Hauptkarte), `layerSplit = "auto"`,
  `cudaArchitectures = ["120" "86"]`.
- Strata füllt jede Karte bis auf `vramReserveMiB` (gilt pro Karte) mit Experten. Läuft
  Strata, bleiben auf der 3080 grob 4 bis 5 GB frei.
- Die letzte Karte rechnet auch Output-Head und Draft-Ebene. Ob der Split mit der
  langsameren 3080 schneller ist als die 5090 allein, ist noch zu messen (Plan, Task 0.1,
  Step 5). Zurück auf eine Karte: `gpu = 0`.

## Belegung nach Modus (geplant, Phase 4)

| Modus | 5090 | 3080 |
|---|---|---|
| `ai-script` | Strata | Strata |
| `ai-produce` | ComfyUI | Chatterbox |
| `ai-off` | Desktop, Resolve, Spiele | frei für VM |
