{pkgs, ...}:
pkgs.writeShellApplication {
  name = "yubikey-update-gpg-stubs";
  runtimeInputs = [pkgs.gnupg];
  excludeShellChecks = ["SC2046" "SC2086"];
  text = ''
    gpg-connect-agent "scd serialno" "learn --force" /bye
  '';
}
