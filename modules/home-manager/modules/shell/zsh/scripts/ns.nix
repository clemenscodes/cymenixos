{
  pkgs,
  config,
  ...
}: let
  text =
    if config.modules.shell.nom.enable
    then "nom shell"
    else "nix shell";
in
  pkgs.writeShellScriptBin "ns" ''
    ${text} "$@"
  ''
