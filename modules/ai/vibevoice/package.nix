{
  lib,
  python3Packages,
  fetchPypi,
  ...
}:
python3Packages.buildPythonPackage rec {
  pname = "vibevoice";
  version = "0.0.1";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    sha256 = "1fcaf03bfbea14f6a651b79b0b077b7eec75e838a16f9c891539be22d5878f24";
  };

  build-system = with python3Packages; [setuptools];

  # vibevoice pins exact versions of accelerate and transformers that are older
  # than what nixpkgs ships; the newer versions remain API-compatible so we
  # disable the strict runtime-dep check instead of downgrading.
  pythonRelaxDeps = ["accelerate" "transformers"];
  nativeBuildInputs = with python3Packages; [pythonRelaxDepsHook];

  dependencies = with python3Packages; [
    torch
    accelerate
    transformers
    llvmlite
    numba
    diffusers
    tqdm
    numpy
    scipy
    librosa
    ml-collections
    absl-py
    gradio
    av
    aiortc
  ];

  pythonImportsCheck = ["vibevoice"];

  meta = {
    description = "VibeVoice: Microsoft's expressive long-form TTS using a 7B LLM";
    homepage = "https://github.com/microsoft/VibeVoice";
    license = lib.licenses.mit;
    mainProgram = "vibevoice";
  };
}
