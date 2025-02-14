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
    read -r -p "Are you sure? Type 'RESET' to continue: " confirm
    if [[ "$confirm" != "RESET" ]]; then
      echo "Aborting..."
      exit 1
    fi

    ykman config mode "OTP+FIDO+CCID" --force || echo "Setting modes to FIDO+CCID failed"

    echo "Resetting OATH (TOTP/HOTP)..."
    ykman oath reset --force || echo "OATH reset failed or not supported"

    echo "Resetting OpenPGP"
    ykman openpgp reset --force || echo "OpenPGP reset failed or not supported"

    echo "Resetting PIV (Smart Card)..."
    ykman piv reset --force || echo "PIV reset failed or not supported"

    echo "Disabling all NFC functions... "
    ykman config nfc --force --disable-all || echo "Disabling all applications over NFC failed"

    echo "Disabling all USB functions... "
    ykman config usb --force --enable OTP || echo "Enabling OTP over USB failed"
    ykman config usb --force --enable FIDO2 || echo "Enabling FIDO2 over USB failed"
    ykman config usb --force --disable U2F || echo "Disabling U2F over USB failed"
    ykman config usb --force --disable OATH || echo "Disabling OATH over USB failed"
    ykman config usb --force --disable PIV || echo "Disabling PIV over USB failed"
    ykman config usb --force --disable OPENPGP || echo "Disabling OPENPGP over USB failed"

    echo "Resetting OTP slot 1"
    ykman otp delete 1 --force
    ykman otp yubiotp 1 --generate-private-id --generate-key --serial-public-id --force

    echo "Resetting OTP slot 2"
    ykman otp delete 2 --force
    ykman otp chalresp 2 --generate --force
  '';
}
