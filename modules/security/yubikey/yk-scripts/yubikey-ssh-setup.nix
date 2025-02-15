{pkgs, ...}:
pkgs.writeShellApplication {
  name = "yubikey-ssh-setup";
  runtimeInputs = [pkgs.openssh];
  excludeShellChecks = ["SC2046" "SC2086"];
  text = ''
    usage() {
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  --help                 Display this help message"
        echo
        echo "Example: $0 \\"
        echo "  --help"
        exit 1
    }

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --help) usage ;;
            *) echo "Unknown option: $1" usage ;;
        esac
    done


    echo "Generating SSH keypair"

    ssh-keygen -t ed25519-sk -N "" -O resident -O verify-required -C "YubiKey" -f ~/.ssh/id_ed25519_sk
  '';
}
