{
  pkgs,
  plugins,
  ...
}:
pkgs.stdenv.mkDerivation {
  name = "git";
  phases = "installPhase";
  installPhase = ''
    mkdir -p $out
    ln -sf ${plugins}/git.yazi/* $out
  '';
}
