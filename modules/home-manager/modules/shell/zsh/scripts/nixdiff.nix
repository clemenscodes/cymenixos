{pkgs, ...}:
pkgs.writeShellScriptBin "nixdiff" ''
  ${pkgs.nvd}/bin/nvd diff /run/current-system $FLAKE/result "$@"
''
