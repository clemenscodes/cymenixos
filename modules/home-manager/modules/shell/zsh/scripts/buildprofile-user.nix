{
  pkgs,
  username,
  ...
}:
pkgs.writeShellScriptBin "buildprofile-user" ''
  sudo nb \
    --profile /nix/var/nix/profiles/system \
    $FLAKE/#nixosConfigurations.${username}.config.system.build.toplevel \
    -o $FLAKE/result \
    --show-trace \
    --no-eval-cache \
    --accept-flake-config "$@"
''
