{pkgs, ...}:
pkgs.writeShellScriptBin "sw-user" ''
  buildprofile-user && nixdiff && switch "$@" && clean
''
