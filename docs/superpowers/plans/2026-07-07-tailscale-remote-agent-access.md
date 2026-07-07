# Remote Access to Local Claude Agents (Tailscale) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a reusable `modules.networking.tailscale` NixOS module to cymenixos and enable it on the amaru system, so Claude agents running in tmux on the desktop can be reached and instructed from a phone anywhere via SSH over a private Tailscale mesh.

**Architecture:** One new option module under `modules/networking/tailscale/` following the exact pattern of `modules/networking/upnp`. It enables `services.tailscale`, opens the firewall via the built-in `openFirewall` + a trusted `tailscale0` interface, and persists `/var/lib/tailscale` for impermanence. It is wired into the `modules/networking/default.nix` aggregator. The amaru system config enables it. Auth and the phone app are one-time manual steps.

**Tech Stack:** Nix / NixOS modules, Tailscale (WireGuard), tmux (already configured), OpenSSH (already configured).

## Global Constraints

- All custom options are namespaced under `modules.*`. Enable option: `modules.networking.tailscale.enable`.
- Module signature must match sibling modules: `{lib, ...}: {config, ...}: { ... }` (the aggregator calls `import ./tailscale {inherit inputs pkgs lib;}`; extra args are ignored via `...`).
- `config` block guarded by `lib.mkIf (cfg.enable && cfg.tailscale.enable)` where `cfg = config.modules.networking` (matches `modules/networking/upnp/default.nix`).
- Impermanence persistence uses the dynamic-key idiom already in `modules/networking/default.nix`: `environment.persistence = lib.mkIf config.modules.boot.enable { ${config.modules.boot.impermanence.persistPath} = { directories = [ ... ]; }; };`.
- **Do NOT set `networking.firewall.checkReversePath`** — amaru already defines it globally (`= false`); redefining causes a conflict.
- Nix flakes only see git-**tracked** files. `git add` new/changed files before any `nix eval`/`nix build` that reads them via a dirty tree.
- Formatting: run `alejandra` on any new/changed `.nix` file before committing (repo standard).
- Local test loop against amaru uses `--override-input cymenixos /home/clemens/.local/src/cymenixos`; amaru's config name is `clemens`; `$FLAKE` = `/home/clemens/.local/src/amaru`.

---

### Task 1: Create the `modules.networking.tailscale` module and wire it into the aggregator

**Files:**
- Create: `/home/clemens/.local/src/cymenixos/modules/networking/tailscale/default.nix`
- Modify: `/home/clemens/.local/src/cymenixos/modules/networking/default.nix` (imports list)

**Interfaces:**
- Consumes: `config.modules.networking.enable`, `config.modules.boot.enable`, `config.modules.boot.impermanence.persistPath` (all pre-existing).
- Produces: options `modules.networking.tailscale.enable` (bool, default `false`) and `modules.networking.tailscale.ssh.enable` (bool, default `true`); when enabled, sets `services.tailscale.enable = true`.

- [ ] **Step 1: Write the module file**

Create `/home/clemens/.local/src/cymenixos/modules/networking/tailscale/default.nix`:

```nix
{lib, ...}: {config, ...}: let
  cfg = config.modules.networking;
in {
  options = {
    modules = {
      networking = {
        tailscale = {
          enable = lib.mkEnableOption "Enable Tailscale mesh VPN for remote access" // {default = false;};
          ssh = {
            enable =
              lib.mkEnableOption "Enable Tailscale SSH (auth via tailnet ACLs)"
              // {default = true;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.tailscale.enable) {
    services = {
      tailscale = {
        enable = true;
        openFirewall = true;
        extraUpFlags = lib.optionals cfg.tailscale.ssh.enable ["--ssh"];
      };
    };
    networking = {
      firewall = {
        trustedInterfaces = ["tailscale0"];
      };
    };
    environment = {
      persistence = lib.mkIf config.modules.boot.enable {
        ${config.modules.boot.impermanence.persistPath} = {
          directories = [
            "/var/lib/tailscale"
          ];
        };
      };
    };
  };
}
```

- [ ] **Step 2: Wire the module into the networking aggregator**

In `/home/clemens/.local/src/cymenixos/modules/networking/default.nix`, add the import line in the `imports = [ ... ]` list, immediately after the `stevenblack` line (alphabetical-ish, next to siblings):

```nix
    (import ./stevenblack {inherit inputs pkgs lib;})
    (import ./tailscale {inherit inputs pkgs lib;})
    (import ./torrent {inherit inputs pkgs lib;})
```

- [ ] **Step 3: Format the changed files**

Run: `cd /home/clemens/.local/src/cymenixos && nix run nixpkgs#alejandra -- modules/networking/tailscale/default.nix modules/networking/default.nix`
Expected: `Formatted ...` / no errors.

- [ ] **Step 4: Stage the files so the flake can see them**

Run: `cd /home/clemens/.local/src/cymenixos && git add modules/networking/tailscale/default.nix modules/networking/default.nix`
Expected: no output (files staged; now tracked by git so flake eval picks them up).

- [ ] **Step 5: Verify the new option evaluates via amaru with the local override**

Run:
```bash
nix eval /home/clemens/.local/src/amaru#nixosConfigurations.clemens.config.modules.networking.tailscale.enable \
  --override-input cymenixos /home/clemens/.local/src/cymenixos
```
Expected: `false` (the option now exists and defaults to false). Before this task it errored with `attribute 'tailscale' missing`.

- [ ] **Step 6: Commit**

```bash
cd /home/clemens/.local/src/cymenixos
git commit -m "feat(networking): add reusable Tailscale module for remote access"
```

---

### Task 2: Enable Tailscale on amaru and verify the built system config

**Files:**
- Modify: `/home/clemens/.local/src/amaru/configuration.nix` (the OS-level `modules.networking` block, which begins `networking = { enable = true; ...` at ~line 572). Do **not** confuse it with the home-manager `modules.networking` block (~line 1424); Tailscale is an OS module.

**Interfaces:**
- Consumes: the `modules.networking.tailscale.enable` option produced by Task 1.
- Produces: a buildable amaru system with `services.tailscale.enable = true` and `--ssh` in `extraUpFlags`.

- [ ] **Step 1: Add the `tailscale` enable to the OS-level `modules.networking` block**

The block (starting ~line 572) currently reads:

```nix
    networking = {
      enable = true;
      bluetooth = {
        enable = true;
      };
      dbus = {
        enable = true;
      };
      firewall = {
        enable = true;
      };
      wireless = {
```

Insert a `tailscale` entry after the `firewall` block:

```nix
      firewall = {
        enable = true;
      };
      tailscale = {
        enable = true;
      };
      wireless = {
```

- [ ] **Step 2: Format the changed file**

Run: `cd /home/clemens/.local/src/amaru && nix run nixpkgs#alejandra -- configuration.nix`
Expected: `Formatted ...` / no errors.

- [ ] **Step 3: Verify the tailscale service is enabled in the built config**

Run:
```bash
nix eval /home/clemens/.local/src/amaru#nixosConfigurations.clemens.config.services.tailscale.enable \
  --override-input cymenixos /home/clemens/.local/src/cymenixos
```
Expected: `true`.

- [ ] **Step 4: Verify Tailscale SSH flag is present**

Run:
```bash
nix eval /home/clemens/.local/src/amaru#nixosConfigurations.clemens.config.services.tailscale.extraUpFlags \
  --override-input cymenixos /home/clemens/.local/src/cymenixos
```
Expected: `[ "--ssh" ]`.

- [ ] **Step 5: Build the full system toplevel (real build, no switch)**

Run:
```bash
nix build /home/clemens/.local/src/amaru#nixosConfigurations.clemens.config.system.build.toplevel \
  --override-input cymenixos /home/clemens/.local/src/cymenixos --no-link --show-trace
```
Expected: builds successfully, no errors. This proves the module composes with the whole amaru system (firewall, impermanence, ssh) with no option conflicts.

- [ ] **Step 6: Commit the amaru change**

```bash
cd /home/clemens/.local/src/amaru
git add configuration.nix
git commit -m "feat: enable Tailscale for remote access to local agents"
```

---

### Task 3: Deploy and bootstrap (manual runbook + end-to-end verification)

This task contains interactive/manual steps that cannot be automated (Tailscale login, phone app). Execute them in order and record the observed output for each.

**Files:** none (deployment + external setup).

**Interfaces:**
- Consumes: the committed cymenixos module (Task 1) and amaru change (Task 2).

- [ ] **Step 1: Push cymenixos so amaru's GitHub input can resolve it**

```bash
cd /home/clemens/.local/src/cymenixos
git push
```
Expected: push succeeds to `github:clemenscodes/cymenixos`.

- [ ] **Step 2: Point amaru at the new cymenixos revision**

```bash
cd /home/clemens/.local/src/amaru
nix flake update cymenixos
git add flake.lock
git commit -m "chore: bump cymenixos for Tailscale module"
```
Expected: `flake.lock` updates the `cymenixos` node to the just-pushed revision.

- [ ] **Step 3: Rebuild and switch the system**

Run: `sudo nixos-rebuild switch --flake "$FLAKE#clemens"`
Expected: activation succeeds; `systemctl status tailscaled` shows the service active.

- [ ] **Step 4: Authenticate the desktop to your tailnet (interactive)**

Run: `sudo tailscale up --ssh`
Expected: prints an auth URL. Open it in a browser, log in with your Tailscale account (GitHub/Google/etc.), approve the machine. `tailscale up` then returns.

Note: the `--ssh` flag is already baked into `extraUpFlags`, but the first `up`/login must be done by hand here.

- [ ] **Step 5: Confirm the node is up**

Run: `tailscale status`
Expected: lists the desktop with a `100.x.y.z` tailnet IP and a MagicDNS name. Note the MagicDNS name (e.g. `clemens-desktop`).

- [ ] **Step 6: Add the phone to the tailnet**

Install the **Tailscale** app (App Store / Play Store) on the phone, log in with the **same** account, toggle it on. Re-run `tailscale status` on the desktop.
Expected: the phone now appears as a second device in the list.

- [ ] **Step 7: End-to-end test — attach to a running agent from the phone**

On the desktop, ensure a Claude agent is running inside tmux (normal usage). On the phone: **turn WiFi off** (to prove it works over mobile data) → open an SSH client (Blink/Termius on iOS, Termius/JuiceSSH on Android, or Tailscale's built-in SSH) → connect to `clemens@<magicdns-name>` → run `tmux attach`.
Expected: live agent output is visible; typing a message and Enter reaches the agent. `Ctrl-b d`-style detach (or the configured `M-Escape` prefix) leaves the session running.

- [ ] **Step 8: Verify persistence survives a reboot**

Reboot the desktop, then run `tailscale status`.
Expected: the node is still authenticated (no re-login prompt), confirming `/var/lib/tailscale` persistence works.

---

## Notes for the implementer

- The `nix eval`/`nix build` commands use `--override-input cymenixos <local path>` so you can test **before** pushing to GitHub. The override only affects that single command; it does not modify amaru's `flake.lock`. The real deploy (Task 3) updates the lock properly.
- If `nix eval` complains it can't find the new files, you forgot `git add` (Task 1 Step 4) — flakes ignore untracked files.
- `services.tailscale.openFirewall` (default `true`, set explicitly here) opens the WireGuard UDP port; the module additionally trusts the `tailscale0` interface so tailnet peers can reach SSH without extra firewall rules.
