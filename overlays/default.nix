{
  inputs,
  pkgs,
  lib,
  system,
  ...
}: [
  (import ./cymenixos-scripts.nix)
  (import ./grub2.nix)
  (import ./obs-vkcapture.nix {inherit inputs;})
  (import ./tongo.nix)
  (import ./xmrig.nix)
  inputs.lutris-overlay.overlays.lutris
  # codex-acp 0.9.4 (in nixpkgs and lutris-overlay) has a broken preBuild: it copies
  # node-version.txt to the vendor root but include_str! in codex-core resolves it one
  # level deeper (source-git-0/). This overlay copies it to the correct location.
  (final: prev: {
    codex-acp = prev.codex-acp.overrideAttrs (old: {
      preBuild =
        (old.preBuild or "")
        + ''
          cp "$NIX_BUILD_TOP/${old.pname}-${old.version}-vendor/node-version.txt" \
             "$NIX_BUILD_TOP/${old.pname}-${old.version}-vendor/source-git-0/node-version.txt"
        '';
    });
  })
  # HDR screencopy: patched Hyprland (wlr-screencopy v4 color_info) and xdph
  # (reads color_info, forwards colorimetry to PipeWire).
  # PQ/HLG/P3 primaries are guarded by #ifdef in xdph; no pipewire patch needed
  # since Hyprland screencopy output is always scRGB linear (ext_linear + bt2020).
  # ((import ./hyprland-patched.nix) {inherit inputs system;})
  # HDR screencopy: patch OBS linux-pipewire plugin to prefer 10-bit formats
  # and map BT.2020 color matrix → VIDEO_CS_2100_PQ for correct HDR rendering.
  # (import ./obs-patched.nix)
]
