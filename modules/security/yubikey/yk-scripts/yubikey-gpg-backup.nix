{pkgs, ...}:
pkgs.writeShellApplication {
  name = "yubikey-gpg-backup";
  runtimeInputs = [pkgs.gnupg];
  excludeShellChecks = ["SC2046" "SC2086"];
  text = ''
    GNUPGHOME="''${GNUPGHOME:-$HOME/.config/gnupg}"
    PASSPHRASE_FILE=""
    ADMIN_PIN_FILE=""
    USER_PIN_FILE=""
    SUBKEYS_FILE=""
    PUBLIC_KEY_FILE=""
    IDENTITY_FILE=""

    usage() {
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  --gnupg-home DIR       Set the GnuPG home directory (default: $GNUPGHOME)"
        echo "  --passphrase-file FILE Path to the passphrase file"
        echo "  --admin-pin-file FILE  Path to the admin pin file"
        echo "  --user-pin-file FILE   Path to the user pin file"
        echo "  --subkeys-file FILE    Path to the subkeys file"
        echo "  --public-key-file FILE Path to the public key file"
        echo "  --identity-file FILE   Path to the indentity file (name and email)"
        echo "  --help                 Display this help message"
        echo
        echo "Example: $0 \\"
        echo "  --gnupg-home ~/.config/gnupg \\"
        echo "  --passphrase-file ./gpg/private/passphrase \\"
        echo "  --admin-pin-file ./gpg/private/admin-pin \\"
        echo "  --user-pin-file ./gpg/private/user-pin \\"
        echo "  --subkeys-file ./gpg/private/subkeys.key \\"
        echo "  --public-key-file ./gpg/public/public-key.asc
        echo "  --identity-file ./gpg/public/identity
        exit 1
    }

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --gnupg-home) GNUPGHOME="$2"; shift 2 ;;
            --passphrase-file) PASSPHRASE_FILE="$2"; shift 2 ;;
            --admin-pin-file) ADMIN_PIN_FILE="$2"; shift 2 ;;
            --user-pin-file) USER_PIN_FILE="$2"; shift 2 ;;
            --subkeys-file) SUBKEYS_FILE="$2"; shift 2 ;;
            --public-key-file) PUBLIC_KEY_FILE="$2"; shift 2 ;;
            --identity-file) IDENTITY_FILE="$2"; shift 2 ;;
            --help) usage ;;
            *) echo "Unknown option: $1"; usage ;;
        esac
    done

    if [[ -z "$PASSPHRASE_FILE" || -z "$ADMIN_PIN_FILE" || -z "$USER_PIN_FILE" || -z "$SUBKEYS_FILE" || -z "$PUBLIC_KEY_FILE" || -z "$IDENTITY_FILE" ]]; then
        echo "Missing required arguments."
        usage
    fi

    echo "Enabling OPENPGP application over USB"
    ykman config usb --enable OPENPGP --force || echo "Failed enabling OPENPGP application over USB"
    ykman openpgp reset --force || echo "Failed resetting OPENPGP application over USB"

    echo "Reading identity from file"
    IDENTITY=$(cat "$IDENTITY_FILE")
    echo "Identity: $IDENTITY"

    echo "Importing public key"
    gpg --homedir "$GNUPGHOME" --import "$PUBLIC_KEY_FILE"

    echo "Importing subkeys"
    CERTIFY_PASS=$(cat "$PASSPHRASE_FILE")
    echo "$CERTIFY_PASS" | gpg --homedir "$GNUPGHOME" --batch --pinentry-mode=loopback --passphrase-fd 0 --import "$SUBKEYS_FILE"

    echo "Setting up YubiKey pins"
    ADMIN_PIN=$(cat "$ADMIN_PIN_FILE")
    USER_PIN=$(cat "$USER_PIN_FILE")

    echo "Updating admin pin"
    ykman openpgp access change-admin-pin -a 12345678 -n "$ADMIN_PIN"

    echo "Updating user pin"
    ykman openpgp access change-pin -P 123456 -n "$USER_PIN"

    echo "Setting smart card attributes"
    gpg --homedir "$GNUPGHOME" --command-fd=0 --pinentry-mode=loopback --edit-card <<EOF
    admin
    login
    $IDENTITY
    $ADMIN_PIN
    quit
    EOF

    echo "Transferring keys to YubiKey"
    KEYID=$(gpg --homedir "$GNUPGHOME" --list-keys --with-colons | awk -F: '/^pub:/ { print $5; exit }')

    gpg --homedir "$GNUPGHOME" --command-fd=0 --pinentry-mode=loopback --edit-key "$KEYID" <<EOF
    key 1
    keytocard
    1
    $CERTIFY_PASS
    $ADMIN_PIN
    key 2
    keytocard
    2
    $CERTIFY_PASS
    $ADMIN_PIN
    key 3
    keytocard
    3
    $CERTIFY_PASS
    $ADMIN_PIN
    save
    EOF

    echo "Configuring touch and retry settings"
    echo "Requiring touch for OpenPGP authentication..."
    ykman openpgp keys set-touch --admin-pin "$ADMIN_PIN" --force aut Cached-Fixed

    echo "Requiring touch for OpenPGP encryption..."
    ykman openpgp keys set-touch --admin-pin "$ADMIN_PIN" --force enc Cached-Fixed

    echo "Requiring touch for OpenPGP signing..."
    ykman openpgp keys set-touch --admin-pin "$ADMIN_PIN" --force sig Cached-Fixed

    echo "Setting OpenPGP retries..."
    ykman openpgp access set-retries --admin-pin "$ADMIN_PIN" --force 3 3 3

    echo "Backup YubiKey setup complete."
  '';
}
