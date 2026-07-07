# Remote access to local Claude agents — design

**Date:** 2026-07-07
**Status:** SUPERSEDED — Tailscale conflicts with amaru's always-on full-tunnel Mullvad (two
WireGuard clients on one host deadlock the routing table + firewall; confirmed live twice).
Replaced by `2026-07-07-wireguard-remote-agent-access-design.md` (self-hosted WireGuard server).

## Problem

Claude Code agents run autonomously on the desktop (`modules.ai.claude`, launched with
`--dangerously-skip-permissions`). The user wants to monitor and instruct these agents
from a phone (or laptop) while away from the desk — e.g. on a walk over mobile data —
without exposing anything to the public internet.

## Key insight

Claude Code is a terminal (TUI) application. "Monitor and instruct my agents remotely"
decomposes into two independent, already-mostly-solved problems:

1. **Keep sessions alive & re-attachable** — agents already run inside `tmux`
   (`modules.shell.multiplexers.tmux`). tmux sessions survive disconnects, so a session
   can be detached and re-attached to the exact running agent later.
2. **Reach the machine securely from anywhere** — the one missing piece. The system has a
   hardened key-only OpenSSH server (`modules.security.ssh`) but no way to dial *in* from
   outside the LAN. Only Mullvad exists, and that is a *client* VPN.

## Existing system state (verified)

- `modules.security.ssh.enable = true` — OpenSSH, key-only, ed25519, `PasswordAuthentication = false`.
- `modules.shell.multiplexers.tmux.enable = true` — persistent sessions. Its zsh auto-attach
  (`exec tmux new-session`) only fires when a graphical display is present, so an **SSH login
  lands at a plain shell** from which `tmux attach` reaches the desktop's running session.
  No change required.
- `modules.ai.claude` — runs agents autonomously.
- **No** Tailscale / WireGuard-inbound / dynamic-DNS module exists.
- Active system config is `amaru` (`$FLAKE`), which consumes cymenixos as a dependency.

## Decisions (confirmed with user)

- **Transport:** Tailscale (WireGuard mesh). No exposed ports, works on mobile data,
  minimal maintenance. Third-party coordination server, but traffic is end-to-end encrypted.
- **Interface:** SSH + tmux only. No web terminal (`ttyd`) — explicitly out of scope.

## Design

### 1. New reusable module — `modules/networking/tailscale/default.nix` (cymenixos)

Follows the existing pattern of `modules.networking.vpn` and `modules.security.ssh`.

- Option `modules.networking.tailscale.enable` — `mkEnableOption`, default `false`.
- Option `modules.networking.tailscale.ssh.enable` — default `true`. When set, adds `--ssh`
  to `services.tailscale.extraUpFlags` so **Tailscale SSH** authenticates connections via
  tailnet ACLs (no private key needed on the phone). The existing hardened OpenSSH server
  remains untouched for all other uses.
- `config` guarded by `lib.mkIf (cfg.enable && cfg.tailscale.enable)`:
  - `services.tailscale.enable = true;`
  - `networking.firewall.trustedInterfaces = ["tailscale0"];`
  - `networking.firewall.allowedUDPPorts = [config.services.tailscale.port];`
  - **Impermanence:** persist `/var/lib/tailscale` (node identity + keys) via the same
    `environment.persistence."${persistPath}"` block used by the ssh module, guarded by
    `lib.mkIf config.modules.boot.enable`. Without this, the node re-authenticates on every boot.

### 2. Wiring

- Import the module in `modules/networking/default.nix` aggregator.
- Add the default value(s) to `api/os.nix`.

### 3. Enable in amaru

In `amaru/configuration.nix`:
```nix
modules.networking.tailscale.enable = true;
```
Then `sudo nixos-rebuild switch --flake "$FLAKE#clemens"`.

### 4. One-time bootstrap (manual, interactive — cannot be automated)

- Desktop: `sudo tailscale up --ssh` → open the printed auth URL → log in with the
  Tailscale account. (If `ssh.enable = true`, the `--ssh` flag is already in `extraUpFlags`,
  but the first `up` / login is still interactive.)
- Phone: install the Tailscale app, log in with the **same** account. Both devices now
  share a private tailnet.

### 5. Runtime workflow ("react to agents on a walk")

- Agents run in tmux on the desktop as usual.
- On the phone: open Tailscale (mesh comes up) → open an SSH client (Blink/Termius on iOS,
  Termius/JuiceSSH on Android, or Tailscale's built-in SSH) → connect to
  `clemens@<desktop-magicdns-name>` → `tmux attach`.
- Live agent output is visible and instructions can be typed. Detach, pocket phone,
  re-attach later — the session never dies.

## Scope boundaries (YAGNI)

- No web terminal (`ttyd`/`wetty`).
- No changes to the tmux or SSH modules.
- No port-forwarding, no dynamic DNS, no VPS relay.
- The module is the only new reusable code; `tailscale up` login and the phone-app setup are
  inherently manual and are documented, not automated.

## Verification / success criteria

1. `nix build "$FLAKE#nixosConfigurations.clemens.config.system.build.toplevel"` succeeds with
   the module enabled (`clemens` is the amaru config name used by the rebuild command).
2. After rebuild + bootstrap, `tailscale status` on the desktop lists both the desktop and phone.
3. From the phone (on mobile data, WiFi off), an SSH connection succeeds and `tmux attach`
   reaches a running Claude agent session; typed input reaches the agent.
4. After a desktop reboot, the node stays authenticated (no re-login), confirming persistence.
