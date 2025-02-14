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

    echo "Resetting FIDO (WebAuthn/U2F)..."
    ykman fido reset --force || echo "FIDO reset failed or not supported"

    echo "Resetting OATH (TOTP/HOTP)..."
    ykman oath reset --force || echo "OATH reset failed or not supported"

    echo "Resetting OpenPGP"
    ykman openpgp reset --force || echo "OpenPGP reset failed or not supported"

    echo "Resetting PIV (Smart Card)..."
    ykman piv reset --force || echo "PIV reset failed or not supported"

    echo "Disabling all NFC functions... "
    ykman config nfc --force --disable-all || echo "Disabling all applications over NFC failed"

    ykman config mode --force FIDO+CCID || echo "Setting modes to FIDO+CCID failed"

    echo "Disabling all USB functions... "
    ykman config usb --force --disable OTP || echo "Disabling OTP over USB failed"
    ykman config usb --force --disable U2F || echo "Disabling U2F over USB failed"
    ykman config usb --force --disable FIDO2 || echo "Disabling FIDO2 over USB failed"
    ykman config usb --force --disable OATH || echo "Disabling OATH over USB failed"
    ykman config usb --force --disable PIV || echo "Disabling PIV over USB failed"
    ykman config usb --force --disable OPENPGP || echo "Disabling OPENPGP over USB failed"
    ykman config usb --force --disable HSMAUTH || echo "Disabling OPENPGP over USB failed"
  '';
}
