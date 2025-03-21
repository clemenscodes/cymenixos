{
  inputs,
  pkgs,
  lib,
  ...
}: [
  (import ./cymenixos-scripts.nix)
  (import ./grub2.nix)
  inputs.chaotic.overlays.default
]
