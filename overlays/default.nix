{
  inputs,
  pkgs,
  lib,
  system,
  ...
}: [
  (import ./cymenixos-scripts.nix)
  (import ./grub2.nix)
  (import ./tongo.nix)
  inputs.lutris-overlay.overlays.lutris
  # HDR screencopy: patched Hyprland (wlr-screencopy v4 color_info) and xdph
  # (reads color_info, forwards colorimetry to PipeWire).
  ((import ./hyprland-patched.nix) {inherit inputs system;})
  # PipeWire with SMPTE2084 PQ, HLG, and P3 primaries enum additions.
  # (import ./pipewire-hdr.nix)
]
