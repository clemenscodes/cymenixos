{pkgs}:
with pkgs;
  stdenv.mkDerivation {
    name = "ps3bios";
    src = fetchurl {
      url = "http://dus01.ps3.update.playstation.net/update/ps3/image/us/2026_0318_a2b60b6ac1d2e49e230144345616927c/PS3UPDAT.PUP";
      sha256 = "0rgk3h0f03rwmzh31jkr7nkpnv6q7jsamdinc41si3jghgyp310m";
    };
    phases = "installPhase";
    installPhase = ''
      mkdir -p $out $out/bios
      cp $src $out/bios/PS3UPDAT.PUP
    '';
  }
