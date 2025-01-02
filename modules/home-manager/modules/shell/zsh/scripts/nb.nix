{
  pkgs,
  config,
  ...
}: let
  text =
    if config.modules.shell.nom.enable
    then "nom build"
    else "nix build";
in
  pkgs.writeShellScriptBin "nb" ''
    ${text} "$@"
  ''
