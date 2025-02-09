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
        echo "  --help                 Display this help message"
        exit 1
    }

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --identity) IDENTITY="$2" shift 2 ;;
            --key-type) KEY_TYPE="$2" shift 2 ;;
            --expiration) EXPIRATION="$2" shift 2 ;;
            --gnupg-home) GNUPGHOME="$2" shift 2 ;;
            --public-key-dest) PUBLIC_KEY_DEST="$2" shift 2 ;;
            --private-key-dest) PRIVATE_KEY_DEST="$2" shift 2 ;;
            --subkeys-dest) SUBKEYS_DEST="$2" shift 2 ;;
            --key-id-file) KEYID_FILE="$2" shift 2 ;;
            --key-fp-file) KEYFP_FILE="$2" shift 2 ;;
            --passphrase-file) PASSPHRASE_FILE="$2" shift 2 ;;
            --admin-pin-file) ADMIN_PIN_FILE="$2" shift 2 ;;
            --user-pin-file) USER_PIN_FILE="$2" shift 2 ;;
            --help) usage ;;
            *) echo "Unknown option: $1" usage ;;
        esac
    done

    mkdir -p "$GNUPGHOME"

    echo "Generating passphrase"

    RANDOM_ENTROPY=$(head -c 1000 /dev/urandom | LC_ALL=C tr -dc 'A-Z1-9' | head -c 1000)
    FILTERED_ENTROPY=$(echo "$RANDOM_ENTROPY" | tr -d "1IOS5U")
    TRIMMED_ENTROPY=$(echo "$FILTERED_ENTROPY" | fold -w 30 | head -1)
    SPLIT_ENTROPY=$(echo "$TRIMMED_ENTROPY" | sed "-es/./ /"{1..26..5})
    CERTIFY_PASS=$(echo "$SPLIT_ENTROPY" | cut -c2- | tr " " "-")

    echo "passphrase: $CERTIFY_PASS"

    if [[ -n "$PASSPHRASE_FILE" ]]; then
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
        echo "Exporting key id to $KEYID_FILE"
        echo "$KEYID" > "$KEYID_FILE"
    fi

    echo "Key fingerprint: $KEYFP"

    if [[ -n "$KEYFP_FILE" ]]; then
        echo "Exporting key fingerprint to $KEYFP_FILE"
        echo "$KEYFP" > "$KEYFP_FILE"
    fi

    echo "Creating subkeys"

    for SUBKEY in sign encrypt auth ; do
        echo $CERTIFY_PASS | gpg --batch --pinentry-mode=loopback --passphrase-fd 0 \
            --quick-add-key $KEYFP $KEY_TYPE $SUBKEY $EXPIRATION
    done

    gpg -K

    echo "Backing up keys"

    CERTIFY_KEY="$PRIVATE_KEY_DEST/$KEYID-Certify.key"
    SUBKEYS="$SUBKEYS_DEST/$KEYID-Subkeys.key"
    PUBLIC_KEY="$PUBLIC_KEY_DEST/$KEYID-$(date +%F).asc"

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

    echo "Re-importing the subkeys..."
    gpg --import "$SUBKEYS"

    echo "Generating pins"

    ADMIN_PIN=$(head -c 1000 /dev/urandom | LC_ALL=C tr -dc '0-9' | head -c 1000 | fold -w8 | head -1)
    USER_PIN=$(head -c 1000 /dev/urandom | LC_ALL=C tr -dc '0-9' | head -c 1000 | fold -w6 | head -1)

    echo "Checking card status"

    gpg --card-status

    echo "Updating admin pin to $ADMIN_PIN"

    gpg --command-fd=0 --pinentry-mode=loopback --change-pin <<EOF
    3
    12345678
    $ADMIN_PIN
    $ADMIN_PIN
    q
    EOF

    if [[ -n "$ADMIN_PIN_FILE" ]]; then
        echo "Exporting admin pin to $ADMIN_PIN_FILE"
        echo $ADMIN_PIN > $ADMIN_PIN_FILE
        chmod 600 $ADMIN_PIN_FILE
    fi

    echo "Updating user pin to $USER_PIN"

    gpg --command-fd=0 --pinentry-mode=loopback --change-pin <<EOF
    1
    123456
    $USER_PIN
    $USER_PIN
    q
    EOF

    if [[ -n "$USER_PIN_FILE" ]]; then
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
  '';
}
