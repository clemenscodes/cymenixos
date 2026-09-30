{
  lib,
  fetchFromGitHub,
  cmake,
  ninja,
  python3,
  cudaPackages_13_0,
  autoAddDriverRunpath,
  addDriverRunpath,
  cudaArchitectures ? ["120"],
}: let
  cudaPackages = cudaPackages_13_0;
  version = "0.1.29";
  # the llama.cpp commit Strata pins (LLAMA_CPP_COMMIT in setup.py): ggml for the engine, gguf-py for the tools
  llamaCpp = fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    rev = "3cf03257f219afbe7334045ff7c6a06ac68c627d";
    hash = "sha256-SRGoXa+4ACBCB3eaG9XFYhMN1i0FyPEy9Rrer+dFGYI=";
  };
  python = python3.withPackages (ps: with ps; [numpy jinja2 regex pyyaml tqdm requests pillow psutil]);
in
  cudaPackages.backendStdenv.mkDerivation {
    pname = "strata";
    inherit version;

    src = fetchFromGitHub {
      owner = "Niko1221";
      repo = "Strata";
      rev = "d6708a4aae15b4860000d54c8af9e84d684bce09";
      hash = "sha256-Unkpm1Wj7qtvZA/uKvm4tJFOUPYOPhCdvoVn9u17xXc=";
    };

    # the monitor loads NVML by name, which the driver on NixOS keeps outside the default library path
    postPatch = ''
      substituteInPlace serve/telemetry.py \
        --replace-fail '["libnvidia-ml.so.1", "libnvidia-ml.so"]' \
                       '["${addDriverRunpath.driverLink}/lib/libnvidia-ml.so.1", "libnvidia-ml.so.1", "libnvidia-ml.so"]'
    '';

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
      "-DSTRATA_ENABLE_CUDA=ON"
      "-DSTRATA_BUILD_TESTS=OFF"
      "-DSTRATA_GGML_DIR=${llamaCpp}"
      "-DCMAKE_CUDA_ARCHITECTURES=${lib.concatStringsSep ";" cudaArchitectures}"
    ];

    ninjaFlags = ["strata"];

    installPhase = ''
      runHook preInstall
      share=$out/share/strata
      mkdir -p $share/engine $out/bin
      cp -r ../serve ../tools ../data ../chat.py $share/
      install -Dm755 strata $share/engine/strata
      # the server reads the engine version from BUILD.json next to the binary
      echo '{"source": "nix", "version": "${version}", "archs": [${lib.concatStringsSep ", " cudaArchitectures}]}' \
        > $share/engine/BUILD.json
      ln -s ${llamaCpp}/gguf-py $share/gguf-py
      ln -s ${python}/bin/python $out/bin/strata-python
      runHook postInstall
    '';

    passthru = {inherit python llamaCpp;};

    meta = {
      description = "Runs Qwen3.8-Flash-Next on one GPU plus system RAM";
      homepage = "https://github.com/Niko1221/Strata";
      license = lib.licenses.mit;
      platforms = ["x86_64-linux"];
    };
  }
