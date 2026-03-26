{
  stdenv,
  fetchurl,
  p7zip,
}:
stdenv.mkDerivation {
  pname = "sc0710-firmware";
  version = "1.1.0.202";

  src = fetchurl {
    url = "https://edge.elgato.com/egc/windows/drivers/4K_Pro/Elgato_4KPro_1.1.0.202.exe";
    hash = "sha256-tl+hj+AisXN5plUqkdEScuN5LPNjvBi5bVFNtWL9HnE=";
  };

  nativeBuildInputs = [p7zip];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    7z e $src "Final/Game_Capture_4K_Pro/SC0710.FWI.HEX" -o./fw
    install -D fw/SC0710.FWI.HEX $out/lib/firmware/sc0710/SC0710.FWI.HEX
    runHook postInstall
  '';
}
