{pkgs, ...}:
pkgs.writeShellScriptBin "clean" ''
  rm -rf $FLAKE/result "$@"
''
