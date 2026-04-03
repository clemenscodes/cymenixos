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
  (import ./xmrig.nix)
  inputs.lutris-overlay.overlays.lutris
  # HDR screencopy: patched Hyprland (wlr-screencopy v4 color_info) and xdph
  # (reads color_info, forwards colorimetry to PipeWire).
  # PQ/HLG/P3 primaries are guarded by #ifdef in xdph; no pipewire patch needed
  # since Hyprland screencopy output is always scRGB linear (ext_linear + bt2020).
  # ((import ./hyprland-patched.nix) {inherit inputs system;})
  # HDR screencopy: patch OBS linux-pipewire plugin to prefer 10-bit formats
  # and map BT.2020 color matrix → VIDEO_CS_2100_PQ for correct HDR rendering.
  # (import ./obs-patched.nix)
]
