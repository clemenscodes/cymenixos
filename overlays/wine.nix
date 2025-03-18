(final: prev: {
  winePackages.unstableFull = prev.winePackages.unstableFull.overrideAttrs (oldAttrs: rec {
    version = "10.3";
    src = prev.fetchurl rec {
      inherit version;
      url = "https://dl.winehq.org/wine/source/10.x/wine-${version}.tar.xz";
      hash = "sha256-3j2I/wBWuC/9/KhC8RGVkuSRT0jE6gI3aOBBnDZGfD4=";
    };
  });
})
