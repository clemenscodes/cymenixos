{
  inputs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.development.reversing;
  ps3IdaOverlay = _: super: {
    ps3ida = super.stdenv.mkDerivation rec {
      name = "ps3ida";
      version = "3d38ddf6a6bc879531ae0434770eef8eed07d7c8";
      src = super.fetchFromGitHub {
        owner = "kakaroto";
        repo = name;
        rev = version;
        hash = "sha256-JiE0Q0bQzsEmT6xME6Rv1LoBwWLYHJ2KMl44QdkaZZw=";
      };
      phases = "installPhase";
      installPhase = ''
        mkdir -p $out
        cp -r $src $out
      '';
    };
  };
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["ida-free"];
    };
    overlays = [ps3IdaOverlay];
  };
in {
  options = {
    modules = {
      development = {
        reversing = {
          ida = {
            enable = lib.mkEnableOption "Enable IDA free" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.ida.enable) {
    home = {
      packages = [
        pkgs.ida-free
        pkgs.ps3ida
      ];
    };
  };
}
