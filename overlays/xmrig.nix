final: prev: {
  xmrig = prev.xmrig.overrideAttrs (_old: rec {
    version = "6.26.0";
    src = final.fetchurl {
      url = "https://github.com/xmrig/xmrig/archive/v${version}.tar.gz";
      hash = "sha256-UAUUTnhXHyZYZBDCsu3isMcq/iL5fxcI6iTPslPDk5s=";
    };
  });
}
