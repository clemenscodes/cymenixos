{pkgs, ...}:
pkgs.writeShellScriptBin "boot" ''
  sudo $FLAKE/result/bin/switch-to-configuration boot "$@"
''
