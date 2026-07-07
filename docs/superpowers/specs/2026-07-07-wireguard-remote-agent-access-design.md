# Remote access to local Claude agents via self-hosted WireGuard — design

**Date:** 2026-07-07
**Status:** Approved, pending implementation plan
**Supersedes:** `2026-07-07-tailscale-remote-agent-access-design.md`

## Problem

Claude Code agents run autonomously in tmux on the amaru desktop. The user wants to monitor
and instruct them from a phone anywhere (mobile data), without exposing anything broadly to the
public internet, and **for free** (no paid SaaS).

## Why not Tailscale (superseded approach)

amaru runs **Mullvad always-on, whole-system, full-tunnel** (WireGuard). Running Tailscale (a
second opinionated WireGuard client) on the same host deadlocked all networking twice: (1)
Tailscale MagicDNS hijacked `/etc/resolv.conf`, and (2) both daemons fought over the default
route + firewall (`fwmark`/policy-routing collision), killing even Mullvad's own tunnel. Two
full VPN clients cannot coexist on one host. The paid fix (Mullvad-via-Tailscale exit node,
~$5/mo) was rejected on cost.

## Key insight

A **hand-rolled WireGuard server** coexists with Mullvad because we control every routing rule:
narrow `AllowedIPs` (mesh subnet only), no default-route capture, no DNS management, no
aggressive netfilter. Only the WireGuard server's own encrypted *transport* packets need to
bypass Mullvad — solved with a single `fwmark` + policy-routing rule.

### Mullvad bypass mechanism (verified live on amaru)

Mullvad installs exactly one redirect rule:
```
5209: not from all fwmark 0x6d6f6c65 lookup 1836018789   # unmarked traffic → Mullvad tunnel
```
Any packet carrying a firewall mark that we route *before* priority 5209 escapes the tunnel via
the physical interface. So we mark the WireGuard interface's transport packets and add a
higher-priority (lower-number) rule sending them out `enp13s0` via the LAN gateway
(`192.168.178.1`). Decrypted mesh traffic (phone→desktop `ssh`) stays on the `wg0` interface and
never touches the default route, so Mullvad ignores it entirely.

## Verified environment facts

- amaru: `$FLAKE` = `/home/clemens/.local/src/amaru`, config name `clemens`, hostname `amaru`.
- Public IPv4 `92.208.103.241` (Deutsche Telekom) — **real, routable, not CGNAT** (`100.64/10`).
  Dual-stack (public IPv6 also present). IPv4 is dynamic (changes ~daily) → needs dynamic DNS.
- Router: FRITZ!Box (`192.168.178.1`), no native Tailscale/WireGuard-client, but supports UDP
  port-forwarding and built-in **MyFRITZ!** dynamic DNS (free).
- Physical LAN interface: `enp13s0`, desktop LAN IP `192.168.178.171`.
- Mullvad fwmark: `0x6d6f6c65`; Mullvad routing table `1836018789`; redirect rule at priority 5209.
- SOPS is configured: `.sops.yaml` age key `age1jkuq0fytqetja77s7u6rvwtf6l3zg94f5en3ek4578n2x6jhaarqkhhkhr`,
  `defaultSopsFile = ./secrets/secrets.yaml`, secrets declared in `amaru/secrets.nix` under
  `sops.secrets.<name>` (e.g. `github_token = { owner; mode = "0440"; }`), edited via
  `sops secrets/secrets.yaml`.
- OpenSSH already hardened + enabled (`modules.security.ssh`), key-only, listens on all
  interfaces including the future `wg0`.
- tmux already persistent (`modules.shell.multiplexers.tmux`); SSH login lands at a shell where
  `tmux attach` reaches the running agent session.

## Decisions (confirmed with user)

- **Transport:** self-hosted WireGuard server on the desktop; **free** (Variant B: home
  port-forward + dynamic DNS). No VPS.
- **Interface:** SSH + tmux over the WireGuard mesh (no web terminal).
- **Keys:** managed via **SOPS** (server private key encrypted in the repo).
- **Code location:** new reusable cymenixos module.

## Design

### 1. New reusable module — `modules/networking/wireguard-server/default.nix` (cymenixos)

Follows the `modules/networking/upnp` pattern. Signature `{lib, ...}: {config, ...}:`.

Options (all under `modules.networking.wireguard-server`):
- `enable` — `mkEnableOption`, default `false`.
- `listenPort` — int, default `51820`.
- `address` — str, default `"10.100.0.1/24"` (server's mesh address).
- `privateKeyFile` — path (required when enabled); points at the SOPS-decrypted secret.
- `peers` — list of `{ publicKey :: str; allowedIPs :: [str]; }` (public keys are not secret).
- `bypassVpn` — sub-options to route transport packets around a conflicting full-tunnel VPN:
  - `enable` — bool, default `false`.
  - `interface` — str (e.g. `"enp13s0"`).
  - `gateway` — str (e.g. `"192.168.178.1"`).
  - `fwMark` — int, default `0x33` (51 — arbitrary, distinct from Mullvad's mark).
  - `table` — int, default `1000`.

`config` (guarded by `lib.mkIf (cfg.enable && cfg.wireguard-server.enable)`):
- `networking.wireguard.interfaces.wg0 = { ips = [address]; inherit listenPort; privateKeyFile;
  peers; }`.
- When `bypassVpn.enable`: set the interface's fwmark and install the policy route via
  `postSetup`/`postShutdown` (idempotent `ip rule`/`ip route` add/del in `table`, at a priority
  below Mullvad's 5209, e.g. `5000`), plus `wg set wg0 fwmark <fwMark>`.
- `networking.firewall.allowedUDPPorts = [listenPort]`.
- No DNS settings, no default-route changes, no impermanence (the private key is provided by
  SOPS at runtime; peer public keys are in the Nix config).

Wire into `modules/networking/default.nix` aggregator import list.

### 2. SOPS secret

- Add `wireguard_private_key` to `amaru/secrets/secrets.yaml` (via `sops`), holding the server's
  WireGuard private key.
- Declare in `amaru/secrets.nix`: `sops.secrets.wireguard_private_key = { mode = "0400"; };`
  (owner root; consumed by the wg service).

### 3. Enable in amaru

`modules.networking.wireguard-server = { enable = true; privateKeyFile =
config.sops.secrets.wireguard_private_key.path; peers = [ { publicKey = "<phone pubkey>";
allowedIPs = ["10.100.0.2/32"]; } ]; bypassVpn = { enable = true; interface = "enp13s0"; gateway
= "192.168.178.1"; }; };`

### 4. Keypairs

- Server keypair generated during bootstrap; private key → SOPS, public key → recorded for the
  phone config.
- Phone keypair generated during bootstrap; phone private key → phone only (via QR, never in the
  repo), phone public key → amaru `peers`.

### 5. Manual bootstrap (user; cannot be automated)

- FRITZ!Box: confirm the connection is **not DS-Lite** (Internet → Connection); forward **UDP
  51820** to the desktop; enable **MyFRITZ!** dynamic DNS → gives a stable `*.myfritz.net` name.
- Phone: install the official **WireGuard** app; import the generated client config via QR. The
  client `Endpoint` is `<name>.myfritz.net:51820`; `AllowedIPs = 10.100.0.1/32` (only reach the
  desktop, no full tunnel through home).

### 6. Runtime workflow

Phone: WireGuard app on → SSH client → `clemens@10.100.0.1` → `tmux attach`. Works over mobile
data because the phone initiates outbound to the home public IPv4 (phone-side CGNAT irrelevant).

## Scope boundaries (YAGNI)

- No web terminal. No changes to tmux/SSH modules.
- No IPv6 path initially (IPv4 port-forward is robust from mobile; IPv6 can be added later).
- The module is generic; the Mullvad-specific bypass is an opt-in feature configured by amaru.
- FRITZ!Box port-forward + MyFRITZ! and the phone app are manual/documented, not automated.

## Verification / success criteria

1. `nix build "$FLAKE#nixosConfigurations.clemens.config.system.build.toplevel"` (with local
   cymenixos override) succeeds; `wg0` unit present, no option conflicts.
2. After rebuild: `sudo wg show wg0` shows the interface up with the peer listed.
3. Desktop browsing still works with Mullvad connected (bypass did not break the default route).
4. From the phone (mobile data, WiFi off): WireGuard handshake succeeds (`wg show` latest
   handshake advances), `ssh clemens@10.100.0.1` connects, `tmux attach` reaches a live agent.
5. After a desktop reboot, `wg0` + the bypass rule return automatically and the phone reconnects.
