final: prev: {
  xmrig = prev.xmrig.overrideAttrs (_old: rec {
    version = "6.26.0";
    src = final.fetchurl {
      url = "https://github.com/xmrig/xmrig/archive/v${version}.tar.gz";
      hash = "sha256-UAUUTnhXHyZYZBDCsu3isMcq/iL5fxcI6iTPslPDk5s=";
    };
    # Build with full native CPU optimizations to enable VAES (Vector AES) and
    # AVX-512 code paths. Without this xmrig falls back to scalar AES-NI for
    # RandomX scratchpad operations, losing ~25-35% hashrate on Zen 5 CPUs.
    NIX_CFLAGS_COMPILE = "-march=native -mtune=native";
  });
}
