# Self-Hosted WireGuard Remote Agent Access — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Add a reusable `modules.networking.wireguard-server` module to cymenixos and enable it on amaru, so a phone can reach Claude agents (in tmux) over a self-hosted WireGuard tunnel that coexists with amaru's always-on full-tunnel Mullvad.

**Architecture:** A hand-rolled WireGuard server interface (`wg0`, `10.100.0.0/24`) with narrow `AllowedIPs` so it never touches the default route. Its encrypted transport packets carry a firewall mark routed (via a policy rule at priority 5000, below Mullvad's 5209) out the physical NIC, bypassing the Mullvad tunnel. Server private key via SOPS. Reachable from the internet via a FRITZ!Box UDP port-forward + MyFRITZ! dynamic DNS.

**Tech Stack:** NixOS `networking.wireguard`, sops-nix, iproute2, wireguard-tools, tmux + OpenSSH (already configured).

## Global Constraints

- Namespace: `modules.networking.wireguard-server`. Enable option default `false`.
- Module signature: `{pkgs, lib, ...}: {config, ...}: { ... }` (aggregator calls `import ./wireguard-server {inherit inputs pkgs lib;}`). `config` guarded by `lib.mkIf (cfg.enable && cfg.wireguard-server.enable)` where `cfg = config.modules.networking`.
- **Do NOT set `networking.firewall.checkReversePath`** (amaru sets it globally). Do NOT set DNS. Do NOT add a `0.0.0.0/0` route.
- Mullvad facts (verified): fwmark `0x6d6f6c65`, redirect rule priority `5209`. Our bypass rule must be a lower priority number (`5000`). Physical iface `enp13s0`, LAN gateway `192.168.178.1`.
- Flakes see only git-**tracked** files: `git add` new files before any `nix eval`/`nix build`.
- Format every new/changed `.nix` with `alejandra` before committing.
- Local test loop: `--override-input cymenixos /home/clemens/.local/src/cymenixos`; amaru config name `clemens`; `$FLAKE` = `/home/clemens/.local/src/amaru`.
- No integer underscores in Nix; `${...}` in multiline Nix strings is antiquotation — use `pkgs`/vars deliberately.

---

### Task 1: Create the `wireguard-server` module and wire it into the aggregator

**Files:**
- Create: `/home/clemens/.local/src/cymenixos/modules/networking/wireguard-server/default.nix`
- Modify: `/home/clemens/.local/src/cymenixos/modules/networking/default.nix`

**Interfaces:**
- Produces options `modules.networking.wireguard-server.{enable,listenPort,address,privateKeyFile,peers,bypassVpn.*}` and, when enabled, `networking.wireguard.interfaces.wg0` + firewall UDP port + bypass policy routing.

- [ ] **Step 1: Write the module**

Create `/home/clemens/.local/src/cymenixos/modules/networking/wireguard-server/default.nix`:

```nix
{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.networking;
  wg = cfg.wireguard-server;
  ip = "${pkgs.iproute2}/bin/ip";
  wgbin = "${pkgs.wireguard-tools}/bin/wg";
in {
  options = {
    modules = {
      networking = {
        wireguard-server = {
          enable = lib.mkEnableOption "Enable a self-hosted WireGuard server" // {default = false;};
          listenPort = lib.mkOption {
            type = lib.types.port;
            default = 51820;
            description = "UDP port the WireGuard server listens on.";
          };
          address = lib.mkOption {
            type = lib.types.str;
            default = "10.100.0.1/24";
            description = "Server address on the WireGuard mesh subnet.";
          };
          privateKeyFile = lib.mkOption {
            type = lib.types.path;
            description = "Path to the server's WireGuard private key (e.g. a SOPS secret path).";
          };
          peers = lib.mkOption {
            type = lib.types.listOf (lib.types.submodule {
              options = {
                publicKey = lib.mkOption {
                  type = lib.types.str;
                  description = "Peer public key (not secret).";
                };
                allowedIPs = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  description = "Mesh IPs routed to this peer, e.g. [\"10.100.0.2/32\"].";
                };
              };
            });
            default = [];
            description = "WireGuard peers (e.g. the phone).";
          };
          bypassVpn = {
            enable = lib.mkEnableOption "Route WG transport around a conflicting full-tunnel VPN" // {default = false;};
            interface = lib.mkOption {
              type = lib.types.str;
              description = "Physical interface to send WG transport packets out of.";
            };
            gateway = lib.mkOption {
              type = lib.types.str;
              description = "LAN gateway for the physical interface.";
            };
            fwMark = lib.mkOption {
              type = lib.types.int;
              default = 51;
              description = "Firewall mark applied to WG transport packets.";
            };
            table = lib.mkOption {
              type = lib.types.int;
              default = 1000;
              description = "Routing table holding the bypass default route.";
            };
            priority = lib.mkOption {
              type = lib.types.int;
              default = 5000;
              description = "ip rule priority (must be below the other VPN's redirect rule).";
            };
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && wg.enable) {
    networking = {
      firewall = {
        allowedUDPPorts = [wg.listenPort];
      };
      wireguard = {
        interfaces = {
          wg0 = {
            ips = [wg.address];
            inherit (wg) listenPort;
            privateKeyFile = toString wg.privateKeyFile;
            peers =
              map (p: {
                inherit (p) publicKey allowedIPs;
              })
              wg.peers;
            postSetup = lib.mkIf wg.bypassVpn.enable ''
              ${wgbin} set wg0 fwmark ${toString wg.bypassVpn.fwMark}
              ${ip} route replace default via ${wg.bypassVpn.gateway} dev ${wg.bypassVpn.interface} table ${toString wg.bypassVpn.table}
              ${ip} rule add fwmark ${toString wg.bypassVpn.fwMark} table ${toString wg.bypassVpn.table} priority ${toString wg.bypassVpn.priority} || true
            '';
            postShutdown = lib.mkIf wg.bypassVpn.enable ''
              ${ip} rule del fwmark ${toString wg.bypassVpn.fwMark} table ${toString wg.bypassVpn.table} priority ${toString wg.bypassVpn.priority} || true
              ${ip} route del default via ${wg.bypassVpn.gateway} dev ${wg.bypassVpn.interface} table ${toString wg.bypassVpn.table} || true
            '';
          };
        };
      };
    };
  };
}
```

- [ ] **Step 2: Wire into the aggregator**

In `/home/clemens/.local/src/cymenixos/modules/networking/default.nix`, add the import after the `vpn` line (keeps rough alphabetical order):

```nix
    (import ./vpn {inherit inputs pkgs lib;})
    (import ./wireguard-server {inherit inputs pkgs lib;})
    (import ./wireless {inherit inputs pkgs lib;})
```

- [ ] **Step 3: Format + stage**

Run:
```bash
cd /home/clemens/.local/src/cymenixos
nix run nixpkgs#alejandra -- modules/networking/wireguard-server/default.nix modules/networking/default.nix
git add modules/networking/wireguard-server/default.nix modules/networking/default.nix
```
Expected: alejandra reports compliance; files staged.

- [ ] **Step 4: Verify the option exists**

Run:
```bash
nix eval /home/clemens/.local/src/amaru#nixosConfigurations.clemens.config.modules.networking.wireguard-server.enable \
  --override-input cymenixos /home/clemens/.local/src/cymenixos
```
Expected: `false`.

- [ ] **Step 5: Commit** (Yubikey touch required)

```bash
git commit -m "feat(networking): add self-hosted wireguard-server module"
```

---

### Task 2: Generate the server keypair and store the private key in SOPS

**Files:**
- Modify: `/home/clemens/.local/src/amaru/secrets/secrets.yaml` (via `sops`)
- Modify: `/home/clemens/.local/src/amaru/secrets.nix` (declare the secret)

**Interfaces:**
- Produces `config.sops.secrets.wireguard_private_key.path` and a recorded server **public** key for the phone config (Task 4).

- [ ] **Step 1: Generate the server keypair**

Run:
```bash
umask 077
cd /tmp/claude-1000/-home-clemens--local-src-cymenixos/*/scratchpad 2>/dev/null || cd /tmp
nix shell nixpkgs#wireguard-tools -c sh -c 'wg genkey | tee wg-server.key | wg pubkey > wg-server.pub'
echo "PRIVATE:"; cat wg-server.key; echo "PUBLIC:"; cat wg-server.pub
```
Expected: prints a base64 private and public key. Record the **public** key for Task 4.

- [ ] **Step 2: Add the private key to the SOPS secrets file**

Run `cd /home/clemens/.local/src/amaru && sops secrets/secrets.yaml` and add a top-level key:
```yaml
wireguard_private_key: <paste the private key from Step 1>
```
Save/close (SOPS re-encrypts with the age key from `.sops.yaml`).

Verify it is encrypted at rest:
```bash
grep -c 'wireguard_private_key' secrets/secrets.yaml   # 1
grep 'ENC\[' secrets/secrets.yaml | head -1            # shows encrypted values
```

- [ ] **Step 3: Declare the secret in `secrets.nix`**

In `/home/clemens/.local/src/amaru/secrets.nix`, inside the `sops.secrets = { ... }` block (next to `github_token`), add:
```nix
      wireguard_private_key = {
        mode = "0400";
      };
```

- [ ] **Step 4: Verify the secret path resolves**

Run:
```bash
cd /home/clemens/.local/src/amaru
nix eval .#nixosConfigurations.clemens.config.sops.secrets.wireguard_private_key.path \
  --override-input cymenixos /home/clemens/.local/src/cymenixos
```
Expected: a `/run/secrets/wireguard_private_key`-style path string.

- [ ] **Step 5: Commit the secret declaration** (Yubikey touch)

```bash
cd /home/clemens/.local/src/amaru
git add secrets/secrets.yaml secrets.nix
git commit -m "feat: add wireguard server private key secret"
```

---

### Task 3: Enable the WireGuard server on amaru and build

**Files:**
- Modify: `/home/clemens/.local/src/amaru/configuration.nix` (OS-level `modules.networking` block)

**Interfaces:**
- Consumes Task 1's options + Task 2's secret path. Produces a buildable amaru with `wg0` + bypass.

- [ ] **Step 1: Add the enable block**

In the OS-level `modules.networking` block (the one starting `networking = { enable = true; ...`), add after the `firewall` entry. **Leave the phone `publicKey` as a placeholder for now — Task 4 fills it after the phone keypair exists.** Use an empty `peers = []` initially so the build is valid:

```nix
      wireguard-server = {
        enable = true;
        privateKeyFile = config.sops.secrets.wireguard_private_key.path;
        peers = [];
        bypassVpn = {
          enable = true;
          interface = "enp13s0";
          gateway = "192.168.178.1";
        };
      };
```

(Note: `config` is already a top-level argument of amaru's `configuration.nix`, so `config.sops...` resolves.)

- [ ] **Step 2: Format + build**

Run:
```bash
cd /home/clemens/.local/src/amaru
nix run nixpkgs#alejandra -- configuration.nix
nix build .#nixosConfigurations.clemens.config.system.build.toplevel \
  --override-input cymenixos /home/clemens/.local/src/cymenixos --no-link --show-trace
```
Expected: builds successfully; a `wireguard-wg0.service` unit is generated.

- [ ] **Step 3: Confirm the wg0 interface config is present**

Run:
```bash
nix eval .#nixosConfigurations.clemens.config.networking.wireguard.interfaces.wg0.listenPort \
  --override-input cymenixos /home/clemens/.local/src/cymenixos
```
Expected: `51820`.

- [ ] **Step 4: Commit** (Yubikey touch)

```bash
git add configuration.nix
git commit -m "feat: enable self-hosted wireguard server on amaru"
```

---

### Task 4: Generate phone config, deploy, bootstrap FRITZ!Box + phone, and verify end-to-end

Manual/interactive runbook. Execute in order.

**Files:**
- Modify: `/home/clemens/.local/src/amaru/configuration.nix` (add the phone peer), then push cymenixos + bump amaru lock.

- [ ] **Step 1: Generate the phone keypair**

```bash
cd /tmp
nix shell nixpkgs#wireguard-tools -c sh -c 'wg genkey | tee wg-phone.key | wg pubkey > wg-phone.pub'
echo "PHONE PRIVATE:"; cat wg-phone.key; echo "PHONE PUBLIC:"; cat wg-phone.pub
```
Record both. Phone **private** stays on the phone only; phone **public** goes into amaru.

- [ ] **Step 2: Add the phone peer to amaru and commit**

Edit `configuration.nix`, replace `peers = [];` with:
```nix
        peers = [
          {
            publicKey = "<PHONE PUBLIC from Step 1>";
            allowedIPs = ["10.100.0.2/32"];
          }
        ];
```
Then:
```bash
cd /home/clemens/.local/src/amaru
nix run nixpkgs#alejandra -- configuration.nix
git add configuration.nix && git commit -m "feat: add phone wireguard peer"
```

- [ ] **Step 3: Push cymenixos and bump amaru's lock**

```bash
cd /home/clemens/.local/src/cymenixos && git push
cd /home/clemens/.local/src/amaru
nix flake update cymenixos
git add flake.lock && git commit -m "chore: bump cymenixos for wireguard-server module"
```

- [ ] **Step 4: Rebuild and switch**

```bash
sudo nixos-rebuild switch --flake "$FLAKE#clemens"
```
Expected: activates; `systemctl status wireguard-wg0` is active.

- [ ] **Step 5: Verify wg0 up and bypass rule present, Mullvad intact**

```bash
sudo wg show wg0
ip rule | grep 'fwmark 0x33'            # our fwMark 51 = 0x33, priority 5000
curl -sS --max-time 8 -o /dev/null -w "browsing http=%{http_code}\n" https://www.youtube.com
```
Expected: `wg show` lists the interface + peer (no handshake yet); the `ip rule` line exists; browsing returns `http=200` (Mullvad still working).

- [ ] **Step 6: FRITZ!Box — confirm not DS-Lite, forward the port, enable DDNS**

In the FRITZ!Box UI:
- Internet → Online Monitor / Connection: confirm a public IPv4 and **no "DS-Lite"** label. (If DS-Lite: stop — IPv4 forward won't work; we pivot to IPv6.)
- Internet → Permit Access → Port Sharing: add a share for the desktop, **UDP 51820 → 51820**.
- Internet → Permit Access → DynDNS / MyFRITZ!: enable **MyFRITZ!**; note the `*.myfritz.net` hostname.

- [ ] **Step 7: Build the phone config**

Create this config and render a QR for the phone (fill in the three values):
```ini
[Interface]
PrivateKey = <PHONE PRIVATE from Step 1>
Address = 10.100.0.2/24

[Peer]
PublicKey = <SERVER PUBLIC from Task 2 Step 1>
Endpoint = <yourname>.myfritz.net:51820
AllowedIPs = 10.100.0.1/32
PersistentKeepalive = 25
```
Render QR:
```bash
cat > /tmp/wg-phone.conf <<'EOF'
# (paste the filled-in config above)
EOF
nix shell nixpkgs#qrencode -c qrencode -t ansiutf8 < /tmp/wg-phone.conf
```
Scan it in the phone's WireGuard app (Add tunnel → Scan from QR code).

- [ ] **Step 8: End-to-end test over mobile data**

On the phone: **turn WiFi off**, enable the WireGuard tunnel, open an SSH client → `clemens@10.100.0.1` → `tmux attach`.
On the desktop verify the handshake:
```bash
sudo wg show wg0 latest-handshakes   # non-zero / recent timestamp for the phone peer
```
Expected: handshake completes; SSH connects; `tmux attach` shows a live agent; typing reaches it.

- [ ] **Step 9: Reboot persistence check**

Reboot the desktop. After boot:
```bash
sudo wg show wg0 ; ip rule | grep 'fwmark 0x33'
```
Expected: `wg0` and the bypass rule are back automatically; the phone reconnects (PersistentKeepalive).

- [ ] **Step 10: Clean up scratch keys**

```bash
shred -u /tmp/wg-server.key /tmp/wg-phone.key /tmp/wg-phone.conf 2>/dev/null; rm -f /tmp/wg-server.pub /tmp/wg-phone.pub
```

---

## Notes for the implementer

- The server private key never leaves SOPS/`/run/secrets`; only the server **public** key is copied into the phone config. Phone private key lives only on the phone.
- If `wireguard-wg0.service` fails at boot with a missing key file, add ordering in the module: `systemd.services.wireguard-wg0 = { after = ["sops-nix.service"]; wants = ["sops-nix.service"]; };` — but verify first; sops-nix usually provisions secrets early enough.
- `fwMark = 51` renders as `0x33` in `ip rule`/`wg show` output — that's why Step 5/9 grep for `0x33`.
- The bypass rule (priority 5000) sits above Mullvad's redirect (5209), so only WG transport packets leave the tunnel; everything else stays on Mullvad. When Mullvad is off, the bypass is harmless (main table default is the same physical gateway).
