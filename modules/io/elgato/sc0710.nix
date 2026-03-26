{
  lib,
  stdenv,
  fetchFromGitHub,
  kernel,
}:
stdenv.mkDerivation rec {
  pname = "sc0710";
  version = "2026.03.21-1";

  src = fetchFromGitHub {
    owner = "Nakildias";
    repo = "sc0710";
    rev = "f1f5a722ccbdfc571450d9397e5e1b85da31f9d3";
    hash = "sha256-8dFfGaMkJfRdHU98P+qXcwb4lYh9fTtk6rFz5X7xjOg=";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = [
    "KBUILD_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];

  installPhase = ''
    runHook preInstall
    install -D build/sc0710.ko \
      $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/media/pci/sc0710/sc0710.ko
    runHook postInstall
  '';

  meta = {
    description = "Linux kernel driver for YUAN/Elgato sc0710 PCIe capture cards (4K60 Pro MK.2, 4K Pro, 12ab:0710)";
    homepage = "https://github.com/Nakildias/sc0710";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
    maintainers = [];
  };
}
