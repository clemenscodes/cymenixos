{pkgs, ...}:
pkgs.writeShellApplication {
  name = "yubikey-gpg-setup";
  runtimeInputs = [pkgs.gnupg];
  excludeShellChecks = ["SC2046" "SC2086"];
  text = ''
    IDENTITY="yubikey <yubikey@example.com>"
    KEY_TYPE="rsa4096"
    EXPIRATION="2y"
    GNUPGHOME="''${GNUPGHOME:-$HOME/config/gnupg}"
    PUBLIC_KEY_DEST="''${GNUPGHOME}"
    PRIVATE_KEY_DEST="''${GNUPGHOME}"
    SUBKEYS_DEST="''${GNUPGHOME}"
    KEYID_FILE=""
    KEYFP_FILE=""
    PASSPHRASE_FILE=""
    ADMIN_PIN_FILE=""
    USER_PIN_FILE=""
    FORCE=0

    usage() {
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  --identity NAME        Set the identity name (default: $IDENTITY)"
        echo "  --key-type TYPE        Set the key type (default: $KEY_TYPE)"
        echo "  --expiration TIME      Set the expiration time (default: $EXPIRATION)"
        echo "  --gnupg-home DIR       Set the GnuPG home directory (default: $GNUPGHOME)"
        echo "  --public-key-dest DIR  Set the public key export destination (default: $PUBLIC_KEY_DEST)"
        echo "  --private-key-dest DIR Set the private key export destination (default: $PRIVATE_KEY_DEST)"
        echo "  --subkeys-dest DIR     Set the subkeys export destination (default: $SUBKEYS_DEST)"
        echo "  --key-id-file FILE     Export the key id to the specified file"
        echo "  --key-fp-file FILE     Export the key fingerprint to the specified file"
        echo "  --passphrase-file FILE Export the certify passphrase to the specified file"
        echo "  --admin-pin-file FILE  Export the admin pin to the specified file"
        echo "  --user-pin-file FILE   Export the user pin to the specified file"
        echo "  --force                Force deleting of GPG keys with given identity"
        echo "  --help                 Display this help message"
        echo
        echo "Example: $0 \\"
        echo "  --identity \"Yubikey <yubikey@example.com>\" \\"
        echo "  --key-type rsa4096 \\"
        echo "  --expiration 2y \\"
        echo "  --gnupg-home $GNUPGHOME \\"
        echo "  --public-key-dest ./gpg/public \\"
        echo "  --private-key-dest ./gpg/private \\"
        echo "  --subkeys-dest ./gpg/private \\"
        echo "  --key-id-file ./gpg/private/keyid \\"
        echo "  --key-fp-file ./gpg/private/keyfp \\"
        echo "  --passphrase-file ./gpg/private/passphrase \\"
        echo "  --admin-pin-file ./gpg/private/admin-pin \\"
        echo "  --user-pin-file ./gpg/private/user-pin \\"
        echo "  --force"
        exit 1
    }

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --identity) IDENTITY="$2"; shift 2 ;;
            --key-type) KEY_TYPE="$2"; shift 2 ;;
            --expiration) EXPIRATION="$2"; shift 2 ;;
            --gnupg-home) GNUPGHOME="$2"; shift 2 ;;
            --public-key-dest) PUBLIC_KEY_DEST="$2"; shift 2 ;;
            --private-key-dest) PRIVATE_KEY_DEST="$2"; shift 2 ;;
            --subkeys-dest) SUBKEYS_DEST="$2"; shift 2 ;;
            --key-id-file) KEYID_FILE="$2"; shift 2 ;;
            --key-fp-file) KEYFP_FILE="$2"; shift 2 ;;
            --passphrase-file) PASSPHRASE_FILE="$2"; shift 2 ;;
            --admin-pin-file) ADMIN_PIN_FILE="$2"; shift 2 ;;
            --user-pin-file) USER_PIN_FILE="$2"; shift 2 ;;
            --force) FORCE=1; shift ;;
            --help) usage ;;
            *) echo "Unknown option: $1" usage ;;
        esac
    done

    echo "Enabling OPENPGP application over USB"

    ykman config usb --enable OPENPGP --force || echo "Failed enabling OPENPGP application over USB"
    ykman openpgp reset --force || echo "Failed resetting OPENPGP application over USB"

    echo "Setting up KDF"

    gpg --command-fd=0 --pinentry-mode=loopback --card-edit <<EOF
    admin
    kdf-setup
    12345678
    EOF

    KEY_EXISTS=$(gpg --batch --list-secret-keys --with-colons | grep -q "$IDENTITY"; echo $?)

    echo "WARNING: This will delete your gpg keys with identity $IDENTITY"

    if [[ "$FORCE" -eq 0 && "$KEY_EXISTS" -eq 0 ]]; then
        read -r -p "Are you sure you want to delete GPG keys with identity $IDENTITY? Type 'DELETE' to continue: " confirm
        if [[ "$confirm" != "DELETE" ]]; then
            echo "Aborting..."
            exit 1
        fi
    fi

    if [[ "$KEY_EXISTS" -eq 0 ]]; then
        echo "Deleting GPG keys with identity $IDENTITY"
        key_id=$(gpg --list-keys --with-colons | grep '^pub' | cut -d: -f5)
        fingerprints=$(gpg --fingerprint $key_id | grep -oP '=\s*([A-F0-9]{4}\s*){9}[A-F0-9]{4}' | tr -d ' =')

        for fingerprint in $fingerprints; do
          if gpg --list-secret-keys "$fingerprint" &>/dev/null; then
              gpg --batch --yes --delete-secret-keys "$fingerprint" &>/dev/null && echo "Secret GPG key deleted with fingerprint $fingerprint"
          fi

          if gpg --list-keys "$fingerprint" &>/dev/null; then
              gpg --batch --yes --delete-keys "$fingerprint" &>/dev/null && echo "GPG key deleted with fingerprint $fingerprint"
          fi
        done

        echo "GPG keys for $IDENTITY have been deleted."
    else
        echo "No GPG keys found for $IDENTITY. Continuing anyway..."
    fi

    mkdir -p "$GNUPGHOME" "$PUBLIC_KEY_DEST" "$PRIVATE_KEY_DEST"

    echo "$IDENTITY" > $PUBLIC_KEY_DEST/identity

    echo "Generating passphrase"

    RANDOM_ENTROPY=$(head -c 1000 /dev/urandom | LC_ALL=C tr -dc 'A-Z1-9' | head -c 1000)
    FILTERED_ENTROPY=$(echo "$RANDOM_ENTROPY" | tr -d "1IOS5U")
    TRIMMED_ENTROPY=$(echo "$FILTERED_ENTROPY" | fold -w 30 | head -1)
    SPLIT_ENTROPY=$(echo "$TRIMMED_ENTROPY" | sed "-es/./ /"{1..26..5})
    CERTIFY_PASS=$(echo "$SPLIT_ENTROPY" | cut -c2- | tr " " "-")

    echo "passphrase: $CERTIFY_PASS"

    if [[ -n "$PASSPHRASE_FILE" ]]; then
        mkdir -p "$(dirname "$PASSPHRASE_FILE")"
        echo "Exporting passphrase to $PASSPHRASE_FILE"
        echo "$CERTIFY_PASS" > "$PASSPHRASE_FILE"
        chmod 600 "$PASSPHRASE_FILE"
    fi

    echo "Creating certify key"

    echo $CERTIFY_PASS | gpg --batch --passphrase-fd 0 --quick-generate-key "$IDENTITY" "$KEY_TYPE" cert never

    KEYID=$(gpg -k --with-colons $IDENTITY | awk -F: '/^pub:/ { print $5; exit }')
    KEYFP=$(gpg -k --with-colons $IDENTITY | awk -F: '/^fpr:/ { print $10; exit }')

    echo "Key id: $KEYID"

    if [[ -n "$KEYID_FILE" ]]; then
        mkdir -p "$(dirname "$KEYID_FILE")"
        echo "Exporting key id to $KEYID_FILE"
        echo "$KEYID" > "$KEYID_FILE"
    fi

    echo "Key fingerprint: $KEYFP"

    if [[ -n "$KEYFP_FILE" ]]; then
        mkdir -p "$(dirname "$KEYFP_FILE")"
        echo "Exporting key fingerprint to $KEYFP_FILE"
        echo "$KEYFP" > "$KEYFP_FILE"
    fi

    echo "Creating subkeys"

    for SUBKEY in sign encrypt auth ; do
        echo $CERTIFY_PASS | gpg --batch --pinentry-mode=loopback --passphrase-fd 0 \
            --quick-add-key $KEYFP $KEY_TYPE $SUBKEY $EXPIRATION
    done

    gpg -K

    echo "Generating revocation certificate"

    PUBLIC_KEY="$PUBLIC_KEY_DEST/$KEYID-$(date +%F)-Public.asc"
    REVOCATION_CERT="$PRIVATE_KEY_DEST/$KEYID-Revocation.asc"
    CERTIFY_KEY="$PRIVATE_KEY_DEST/$KEYID-Certify.asc"
    SUBKEYS="$SUBKEYS_DEST/$KEYID-Subkeys.asc"

    mkdir -p "$(dirname "$CERTIFY_KEY")" "$(dirname "$SUBKEYS")" "$(dirname "$PUBLIC_KEY")"

    echo $CERTIFY_PASS | gpg --output "$REVOCATION_CERT" \
        --batch --pinentry-mode=loopback --passphrase-fd 0 \
        --gen-revoke "$KEYID"

    echo "Revocation certificate saved to $REVOCATION_CERT"

    echo "Backing up keys"

    echo $CERTIFY_PASS | gpg --output "$CERTIFY_KEY" \
        --batch --pinentry-mode=loopback --passphrase-fd 0 \
        --armor --export-secret-keys "$KEYID"

    echo $CERTIFY_PASS | gpg --output "$SUBKEYS" \
        --batch --pinentry-mode=loopback --passphrase-fd 0 \
        --armor --export-secret-subkeys "$KEYID"

    echo "Exporting public key"

    gpg --output "$PUBLIC_KEY" \
        --armor --export "$KEYID"

    sudo chmod 0444 "$PUBLIC_KEY"

    echo "Deleting master secret key from local keyring..."
    gpg --batch --yes --delete-secret-keys "$KEYFP"

    echo "Re-importing the public key..."
    gpg --import "$PUBLIC_KEY"

    echo "Re-importing the subkeys..."
    echo $CERTIFY_PASS | gpg \
      --batch --pinentry-mode=loopback --passphrase-fd 0 \
      --import "$SUBKEYS"

    echo "Generating pins"

    ADMIN_PIN=$(head -c 1000 /dev/urandom | LC_ALL=C tr -dc '0-9' | head -c 1000 | fold -w8 | head -1)
    USER_PIN=$(head -c 1000 /dev/urandom | LC_ALL=C tr -dc '0-9' | head -c 1000 | fold -w6 | head -1)

    echo "Checking card status"

    gpg --card-status

    echo "Updating admin pin to $ADMIN_PIN"

    ykman openpgp access change-admin-pin -a 12345678 -n $ADMIN_PIN

    if [[ -n "$ADMIN_PIN_FILE" ]]; then
        mkdir -p "$(dirname "$ADMIN_PIN_FILE")"
        echo "Exporting admin pin to $ADMIN_PIN_FILE"
        echo $ADMIN_PIN > $ADMIN_PIN_FILE
        chmod 600 $ADMIN_PIN_FILE
    fi

    echo "Updating user pin to $USER_PIN"

    ykman openpgp access change-pin -P 123456 -n $USER_PIN

    if [[ -n "$USER_PIN_FILE" ]]; then
        mkdir -p "$(dirname "$USER_PIN_FILE")"
        echo "Exporting user pin to $USER_PIN_FILE"
        echo $USER_PIN > $USER_PIN_FILE
        chmod 600 $USER_PIN_FILE
    fi

    echo "Setting smart card attributes"

    gpg --command-fd=0 --pinentry-mode=loopback --edit-card <<EOF
    admin
    login
    $IDENTITY
    $ADMIN_PIN
    quit
    EOF

    echo "Verifying results"

    gpg --card-status

    echo "Transferring signature key"

    gpg --command-fd=0 --pinentry-mode=loopback --edit-key $KEYID <<EOF
    key 1
    keytocard
    1
    $CERTIFY_PASS
    $ADMIN_PIN
    save
    EOF

    echo "Transferring encryption key"

    gpg --command-fd=0 --pinentry-mode=loopback --edit-key $KEYID <<EOF
    key 2
    keytocard
    2
    $CERTIFY_PASS
    $ADMIN_PIN
    save
    EOF

    echo "Transferring authentication key"

    gpg --command-fd=0 --pinentry-mode=loopback --edit-key $KEYID <<EOF
    key 3
    keytocard
    3
    $CERTIFY_PASS
    $ADMIN_PIN
    save
    EOF

    echo "Verifying transfers"

    gpg -K

    echo "Requiring touch for OpenPGP authentication... "
    ykman openpgp keys set-touch --admin-pin $ADMIN_PIN --force aut Cached-Fixed

    echo "Requiring touch for OpenPGP encryption... "
    ykman openpgp keys set-touch --admin-pin $ADMIN_PIN --force enc Cached-Fixed

    echo "Requiring touch for OpenPGP signing... "
    ykman openpgp keys set-touch --admin-pin $ADMIN_PIN --force sig Cached-Fixed

    echo "Setting openpgp retries"
    ykman openpgp access set-retries --admin-pin $ADMIN_PIN --force 3 3 3
  '';
}
