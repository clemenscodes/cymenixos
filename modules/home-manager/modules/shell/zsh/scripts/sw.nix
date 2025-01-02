{pkgs, ...}:
pkgs.writeShellScriptBin "sw" ''
  buildprofile && nixdiff && switch && clean "$@"
''
