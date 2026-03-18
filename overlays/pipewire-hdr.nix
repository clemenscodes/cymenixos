# Patch PipeWire's SPA video color enums to add HDR transfer functions and
# primaries that are missing from the upstream 1.4.x release series:
#   SPA_VIDEO_TRANSFER_SMPTE2084_PQ  (HDR10 Perceptual Quantizer)
#   SPA_VIDEO_TRANSFER_HLG           (Hybrid Log-Gamma)
#   SPA_VIDEO_COLOR_PRIMARIES_DCI_P3
#   SPA_VIDEO_COLOR_PRIMARIES_DISPLAY_P3
#
# xdg-desktop-portal-hyprland uses #ifdef guards for these values, so it builds
# correctly against both patched and unpatched PipeWire.  Applications (OBS,
# DaVinci Resolve) compiled against this patched PipeWire will receive correct
# color metadata for HDR screencasts.
final: prev: {
  pipewire = prev.pipewire.overrideAttrs (old: {
    patches = (old.patches or []) ++ [
      ../patches/pipewire-spa-hdr-transfer-functions.patch
    ];
  });
}
