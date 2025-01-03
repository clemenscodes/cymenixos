{pkgs, ...}:
pkgs.writeShellScriptBin "sw" ''
  buildprofile-user && nixdiff && switch && clean "$@"
''
