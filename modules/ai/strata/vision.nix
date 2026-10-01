{
  lib,
  cmake,
  ninja,
  cudaPackages_13_0,
  autoAddDriverRunpath,
  strata,
  cudaArchitectures ? ["120"],
}: let
  cudaPackages = cudaPackages_13_0;
in
  cudaPackages.backendStdenv.mkDerivation {
    pname = "strata-vision";
    inherit (strata) version src;

    # tools/vision is its own CMake project and pulls llama.cpp in for mtmd
    sourceRoot = "${strata.src.name}/tools/vision";

    nativeBuildInputs = [
      cmake
      ninja
      cudaPackages.cuda_nvcc
      autoAddDriverRunpath
    ];

    buildInputs = with cudaPackages; [
      cuda_cudart
      cuda_cccl
      libcublas
    ];

    cmakeFlags = [
      "-DLLAMA_DIR=${strata.llamaCpp}"
      "-DSTRATA_VISION_CUDA=ON"
      # GGML_NATIVE is forced on otherwise, which tunes the CPU code to the build machine
      "-DSTRATA_PORTABLE=ON"
      "-DCMAKE_CUDA_ARCHITECTURES=${lib.concatStringsSep ";" cudaArchitectures}"
    ];

    ninjaFlags = ["strata-vision"];

    installPhase = ''
      runHook preInstall
      install -Dm755 bin/strata-vision $out/bin/strata-vision
      runHook postInstall
    '';

    meta = {
      description = "Image encoder for Strata's multimodal path (llama.cpp mtmd)";
      homepage = "https://github.com/Niko1221/Strata";
      license = lib.licenses.mit;
      platforms = ["x86_64-linux"];
      mainProgram = "strata-vision";
    };
  }
