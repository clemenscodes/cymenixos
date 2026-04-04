{
  lib,
  python3Packages,
  fetchPypi,
  transformers451,
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

  dependencies = with python3Packages; [
    torch
    accelerate
    transformers451
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

  # vibevoice pins accelerate==1.6.0 and transformers==4.51.3 exactly.
  # nixpkgs ships newer accelerate; our transformers451 satisfies the transformers pin.
  # Relax all version constraints so pythonRuntimeDepsCheckHook passes.
  pythonRelaxDeps = true;
  nativeBuildInputs = with python3Packages; [pythonRelaxDepsHook];

  pythonImportsCheck = ["vibevoice"];

  meta = {
    description = "VibeVoice: Microsoft's expressive long-form TTS using a 7B/1.5B LLM";
    homepage = "https://github.com/microsoft/VibeVoice";
    license = lib.licenses.mit;
  };
}
