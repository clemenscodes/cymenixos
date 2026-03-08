{
  inputs,
  pkgs,
  lib,
  ...
}: [
  (import ./cymenixos-scripts.nix)
  (import ./grub2.nix)
  (import ./tongo.nix)
  inputs.lutris-overlay.overlays.lutris
]
