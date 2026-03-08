# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CymenixOS is a NixOS flake that exposes reusable NixOS modules for general use cases. It is designed to be consumed as a dependency by other NixOS projects and provides a full system with sensible defaults.

## Development Environment

Enter the dev shell (provides `nil`, `alejandra`, and all build scripts):
```bash
nix develop
# or automatically via direnv: direnv allow
```

Format Nix code:
```bash
alejandra .
```

## Build Commands

These scripts are available inside the dev shell:

| Command | Description |
|---|---|
| `build-system` | Build main NixOS system (`nixosConfigurations.nixos`) |
| `build-offline-system` | Build offline NixOS system |
| `build-iso` | Build installation ISO |
| `build-offline-iso` | Build offline ISO |
| `build-test-iso` | Build test ISO |
| `qemu-run-iso` | Run built ISO in QEMU/KVM VM |
| `cymenixos-install [config]` | Install system via disko (default: `$FLAKE#nixos`) |
| `export-update` | Export system closure for airgap updates |

Direct Nix commands (equivalent):
```bash
# Build system
nix build .#nixosConfigurations.nixos.config.system.build.toplevel --show-trace

# Build ISO
nix build .#nixosConfigurations.iso.config.system.build.isoImage --show-trace
```

## Architecture

### Module System

All custom options are namespaced under `modules.*`. The root module at `modules/default.nix` aggregates 31 category modules and passes `{inputs, pkgs, lib, cymenixos}` to each.

Module signature pattern:
```nix
{inputs, pkgs, lib, ...}: {config, ...}: {
  imports = [...];
  options = { modules.category.feature = lib.mkEnableOption "..."; };
  config = lib.mkIf config.modules.category.feature.enable { ... };
}
```

### Top-level Module Categories (`modules/`)

- **ai** — Claude, Ollama, Voxtype
- **airgap** — Air-gapped/offline system configs
- **boot** — Bootloader, Secure Boot (lanzaboote), hibernation
- **config** — Nix settings, Cachix
- **cpu** — AMD/Intel CPU configs, MSR
- **crypto** — Cardano, Monero, mining tools
- **databases** — MongoDB, PostgreSQL
- **disk** — Disko disk partitioning, LUKS, btrfs/swap
- **display** — Hyprland, GNOME, Plasma, SDDM, GTK/Qt
- **fonts** — Font packages
- **gaming** — Steam, Lutris, emulation
- **gpu** — AMD (LACT/CoreCtrl), NVIDIA
- **home-manager** — Integrates home-manager modules
- **hostname** — System hostname
- **io** — Sound (pipewire), printing, input-remapper
- **locale** — Localization
- **machine** — Machine type profiles (desktop, laptop, server)
- **networking** — Bluetooth, firewall, VPN, wireless
- **nyx** — Chaotic-Nyx package repository
- **performance** — Auto-cpufreq, TLP, thermald
- **rgb** — RGB lighting
- **security** — SSH, GPG, Yubikey, TPM, SOPS secrets
- **shell** — Zsh, environment, console
- **themes** — Catppuccin Macchiato Blue
- **time** — Timezone
- **users** — User/group management
- **virtualisation** — Docker, Podman, Virt-Manager (NixVirt)
- **wsl** — WSL2 support
- **xdg** — XDG base directories

### Home Manager Modules (`modules/home-manager/`)

User-level configuration organized under the same `modules.*` namespace, covering: browser, development tools, display (Hyprland, Waybar, Rofi), editors (Neovim/Zed/JetBrains), media, shell (tmux/zellij/starship), security (bitwarden/GPG/SSH/SOPS), storage (rclone).

### Key Supporting Files

- `api/os.nix` — Default OS-level option values (reference for all available options)
- `api/home.nix` — Default Home Manager option values
- `lib/` — Custom Nix library functions
- `overlays/` — Custom package overlays (scripts, lutris, etc.)
- `examples/` — Complete example configurations (`desktop/`, `minimal/`, `airgap/`, `full/`, etc.)

### Flake Outputs

The flake exposes `nixosModules.${system}.default` for consumption by downstream projects. Key NixOS configurations defined internally: `nixos` (main), `offline`, `iso`, `offline-iso`, `test`, `offline-test`.

## Usage as Dependency

```nix
inputs.cymenixos.url = "github:clemenscodes/cymenixos";
# In nixosSystem modules:
cymenixos.nixosModules.${system}.default
# Then configure via:
modules.enable = true;
modules.display.hyprland.enable = true;
```
