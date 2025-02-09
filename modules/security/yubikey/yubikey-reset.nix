{pkgs, ...}:
pkgs.writeShellApplication {
  name = "yubikey-reset";
  runtimeInputs = [
    pkgs.gnupg
    pkgs.yubikey-manager
  ];
  excludeShellChecks = ["SC2046" "SC2086"];
  text = ''
    echo "WARNING: This will reset your YubiKey to factory settings!"
    read -pr "Are you sure? Type 'RESET' to continue: " confirm
    if [[ "$confirm" != "RESET" ]]; then
      echo "Aborting..."
      exit 1
    fi

    echo "Resetting OTP..."
    ykman otp delete 1 --force || echo "OTP slot 1 reset failed or not supported"
    ykman otp delete 2 --force || echo "OTP slot 2 reset failed or not supported"

    echo "Resetting PIV (Smart Card)..."
    ykman piv reset --force || echo "PIV reset failed or not supported"

    echo "Resetting OpenPGP"
    ykman openpgp reset --force || echo "OpenPGP reset failed or not supported"

    echo "Resetting FIDO (WebAuthn/U2F)..."
    ykman fido reset --force || echo "FIDO reset failed or not supported"

    echo "Resetting OATH (TOTP/HOTP)..."
    ykman oath reset --force || echo "OATH reset failed or not supported"
  '';
}
