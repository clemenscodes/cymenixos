{
  lib,
  stdenv,
  fetchFromGitHub,
  xz,
  kernel,
}:
stdenv.mkDerivation rec {
  pname = "sc0710";
  version = "2026.07.29-1";

  src = fetchFromGitHub {
    owner = "Nakildias";
    repo = "sc0710";
    rev = "cbf0ba52b0f749b4f3ea7f79d92f50e1a892f56d";
    hash = "sha256-xRMCL4HM8wo3LY3mDuUniFo8/9/asx/h6ydFSLckjZE=";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies ++ [xz];

  makeFlags = [
    "KBUILD_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];

  installPhase = ''
    runHook preInstall
    install -D build/sc0710.ko \
      $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/media/pci/sc0710/sc0710.ko
    xz --check=crc32 --lzma2=dict=1MiB $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/media/pci/sc0710/sc0710.ko
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
