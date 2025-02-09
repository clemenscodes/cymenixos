{
  pkgs,
  plugins,
  ...
}:
pkgs.stdenv.mkDerivation {
  name = "smart-enter";
  phases = "installPhase";
  installPhase = ''
    mkdir -p $out
    ln -sf ${plugins}/git.yazi/* $out
  '';
}
