{pkgs, ...}:
pkgs.writeShellApplication {
  name = "yubikey-pubkey-url";
  runtimeInputs = [pkgs.gnupg];
  text = ''
    PUBLIC_KEY_URL=""

    usage() {
        echo "Usage: $0 --public-key-url URL"
        echo "Options:"
        echo "  --public-key-url URL   Set the public key URL on the YubiKey"
        echo "  --help                 Display this help message"
        exit 1
    }

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --public-key-url) PUBLIC_KEY_URL="$2"; shift 2 ;;
            --help) usage ;;
            *) echo "Unknown option: $1"; usage ;;
        esac
    done

    if [[ -z "$PUBLIC_KEY_URL" ]]; then
        echo "Error: --public-key-url must be specified."
        usage
    fi

    echo "Setting public key URL on YubiKey to $PUBLIC_KEY_URL..."
    gpg --command-fd=0 --pinentry-mode=loopback --edit-card <<EOF
    admin
    url
    $PUBLIC_KEY_URL
    quit
    EOF

    echo "Public key URL set successfully!"
  '';
}
