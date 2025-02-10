{pkgs, ...}:
pkgs.rustPlatform.buildRustPackage rec {
  pname = "gpu-usage-waybar";
  version = "0.1.2";
  src = pkgs.fetchFromGitHub {
    owner = "cymenix";
    repo = pname;
    rev = "b92311709f29a28c3f4f52172ae82d7ea34d1eac";
    hash = "sha256-Q3AtM5fCtmPRYTIRKDW+ROpS0TV0jpnw8XtQNO5JSpo=";
  };
  cargoHash = "sha256-TOV+0cB2OmtsixBBLGYod1YJckx9a2Ar+uJWcKGqM/0=";
}
