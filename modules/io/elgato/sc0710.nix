{
  lib,
  stdenv,
  fetchFromGitHub,
  xz,
  kernel,
}:
stdenv.mkDerivation rec {
  pname = "sc0710";
  version = "2026.11.13-1";

  src = fetchFromGitHub {
    owner = "Nakildias";
    repo = "sc0710";
    rev = "60753c530e26aa5b616d507b8f90872c1bca2870";
    hash = "sha256-K0aYytTax28qv3vkxIk53M+RPgrpZ25i2yxKaKlSOYU=";
  };

  # A video chain falls back to smaller DMA segments when ZONE_DMA32 holds no
  # 4 MiB block, instead of leaving the channel unusable until the next resize,
  # and the sound card keeps the id sc0710, which hw:CARD=sc0710 names.
  patches = [./sc0710-dma-and-card-id.patch];

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
