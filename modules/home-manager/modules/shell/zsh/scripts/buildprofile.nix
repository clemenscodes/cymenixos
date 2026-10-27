{
  pkgs,
  username,
  machine,
  ...
}:
pkgs.writeShellScriptBin "buildprofile" ''
  # Build as the user, so private git+ssh inputs are fetched with the user's SSH
  # agent; root has no access to them. Only setting the system profile needs root.
  nb \
    $FLAKE/#nixosConfigurations.${username}.${machine}.config.system.build.toplevel \
    -o $FLAKE/result \
    --show-trace \
    --no-eval-cache \
    --accept-flake-config "$@" &&
  sudo nix-env --profile /nix/var/nix/profiles/system --set "$(readlink -f "$FLAKE/result")"
''
