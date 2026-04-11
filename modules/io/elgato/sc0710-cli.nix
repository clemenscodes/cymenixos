{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  kmod,
  util-linux,
  pciutils,
  psmisc,
  curl,
}:
stdenv.mkDerivation {
  pname = "sc0710-cli";
  version = "2026.03.21-1";

  src = fetchFromGitHub {
    owner = "Nakildias";
    repo = "sc0710";
    rev = "f1f5a722ccbdfc571450d9397e5e1b85da31f9d3";
    hash = "sha256-8dFfGaMkJfRdHU98P+qXcwb4lYh9fTtk6rFz5X7xjOg=";
  };

  nativeBuildInputs = [makeWrapper];

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -D -m755 scripts/sc0710-cli.sh $out/bin/sc0710-cli
    wrapProgram $out/bin/sc0710-cli \
      --prefix PATH : ${
      lib.makeBinPath [
        kmod
        util-linux
        pciutils
        psmisc
        curl
      ]
    }
    runHook postInstall
  '';

  meta = {
    description = "CLI control utility for YUAN/Elgato sc0710 capture cards";
    homepage = "https://github.com/Nakildias/sc0710";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
    mainProgram = "sc0710-cli";
  };
}
