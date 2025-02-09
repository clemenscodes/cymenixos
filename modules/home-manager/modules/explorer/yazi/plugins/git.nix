{pkgs, ...}: let
  plugins = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "07258518f3bffe28d87977bc3e8a88e4b825291b";
    hash = "sha256-axoMrOl0pdlyRgckFi4DiS+yBKAIHDhVeZQJINh8+wk=";
  };
in
  pkgs.stdenv.mkDerivation {
    name = "git";
    phases = "installPhase";
    installPhase = ''
      mkdir -p $out
      ln -sf ${plugins}/git.yazi $out
    '';
  }
