# Patch OBS linux-pipewire plugin for HDR screencopy:
# 1. Prefer 10-bit (xBGR_210LE) over 8-bit (BGRA) in format negotiation
# 2. Map SPA BT2020 color matrix → VIDEO_CS_2100_PQ so OBS treats the
#    source as Rec.2100 PQ rather than defaulting to sRGB (which causes
#    catastrophic overbright when HDR compositors send PQ-encoded data).
final: prev: {
  obs-studio = prev.obs-studio.overrideAttrs (old: {
    patches = (old.patches or []) ++ [./obs-hdr-screencopy.patch];
  });
}
