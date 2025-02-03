# CYMENIXOS Airgap

This is an example using `cymenixos` for an airgapped system.

The following instructions assume that you are inside the devShell of the root [flake.nix](../../flake.nix).

## Building and running an ISO

```sh
nix flake update && build-system && build-test-iso && qemu-run-iso
```

## Running an ISO with USB passthrough

```sh
qemu-run-iso -usb -device qemu-xhci -device usb-host,hostbus=<HOSTBUS>,hostaddr=<HOSTADDR>'
```
