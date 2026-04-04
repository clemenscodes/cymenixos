{
  lib,
  python3Packages,
  fetchPypi,
  ...
}:
# transformers 4.51.3 — the version microsoft/VibeVoice-1.5B was built and tested with.
python3Packages.buildPythonPackage rec {
  pname = "transformers";
  version = "4.51.3";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-4pL8qzmQxt7+Yyjw99IAQoPKgaegey3ppG1n/YHqFAk=";
  };

  build-system = with python3Packages; [setuptools];

  dependencies = with python3Packages; [
    filelock
    huggingface-hub
    numpy
    packaging
    pyyaml
    regex
    requests
    safetensors
    tokenizers
    tqdm
  ];

  # nixpkgs tokenizers (0.22+) and huggingface-hub (1.x) are newer than the upper
  # bounds transformers 4.51.3 pins but remain API-compatible.
  pythonRelaxDeps = [
    "huggingface-hub"
    "tokenizers"
  ];
  nativeBuildInputs = with python3Packages; [pythonRelaxDepsHook];

  postPatch = ''
    # Remove strict upper-bound version pins that would raise ImportError at startup
    find . -name "dependency_versions_table.py" | \
      xargs sed -i \
        -e 's/tokenizers>=0\.21,<0\.22/tokenizers>=0.21/' \
        -e 's/huggingface-hub>=0\.30\.0,<1\.0/huggingface-hub>=0.30.0/'
  '';

  doCheck = false;

  pythonImportsCheck = ["transformers"];

  meta = {
    description = "transformers 4.51.3 (VibeVoice-compatible)";
    license = lib.licenses.asl20;
  };
}
