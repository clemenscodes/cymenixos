{pkgs, ...}:
pkgs.writeShellScriptBin "swupdate" ''
  update && sw "$@"
''
