{pkgs}:
with pkgs;
  stdenv.mkDerivation {
    name = "ps3bios";
    src = fetchurl {
      url = "http://dus01.ps3.update.playstation.net/update/ps3/image/us/2025_0305_c179ad173bbc08b55431d30947725a4b/PS3UPDAT.PUP";
      sha256 = "0r6lr7ify6g7kbqgfah1d4dknllkz4hpvsp4zs7k7l4h68ll9h4r";
    };
    phases = "installPhase";
    installPhase = ''
      mkdir -p $out $out/bios
      cp $src $out/bios/PS3UPDAT.PUP
    '';
  }
