final: pkgs: {
  tongo = pkgs.rustPlatform.buildRustPackage rec {
    pname = "tongo";
    version = "v0.15.1";
    src = pkgs.lib.cleanSource (pkgs.fetchFromGitHub {
      owner = "drewzemke";
      repo = "tongo";
      rev = version;
      hash = "sha256-Sn1bYBBjOqORed1m0x+oxQXKSh37/+kukNIIdgoxQrk=";
    });
    cargoLock = {
      lockFile = "${src}/Cargo.lock";
    };
  };
}
