{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.security;
  viewYubikeyGuide = pkgs.writeShellScriptBin "view-yubikey-guide" ''
    viewer="$(type -P xdg-open || true)"
    if [ -z "$viewer" ]; then
      viewer="${pkgs.glow}/bin/glow -p"
    fi
    exec $viewer "${inputs.yubikey-guide}/README.md"
  '';
  shortcut = pkgs.makeDesktopItem {
    name = "yubikey-guide";
    icon = "${pkgs.yubikey-manager-qt}/share/icons/hicolor/128x128/apps/ykman.png";
    desktopName = "drduh's YubiKey Guide";
    genericName = "Guide to using YubiKey for GnuPG and SSH";
    comment = "Open the guide in a reader program";
    categories = ["Documentation"];
    exec = "${viewYubikeyGuide}/bin/view-yubikey-guide";
  };
  yubikeyGuide = pkgs.symlinkJoin {
    name = "yubikey-guide";
    paths = [viewYubikeyGuide shortcut];
  };
  yubikey-gpg-setup = pkgs.writeShellApplication {
    name = "yubikey-gpg-setup";
    runtimeInputs = [pkgs.gnupg];
    excludeShellChecks = ["SC2046" "SC2086"];
    text = ''
      IDENTITY="yubikey"
      KEY_TYPE="rsa4096"
      EXPIRATION="2y"
      GNUPGHOME="''${GNUPGHOME:-$HOME/.gnupg}"
      PUBLIC_KEY_DEST="''${GNUPGHOME}"
      PASSPHRASE_FILE=""
      ADMIN_PIN_FILE=""
      USER_PIN_FILE=""

      usage() {
          echo "Usage: $0 [options]"
          echo "Options:"
          echo "  --identity NAME       Set the identity name (default: $IDENTITY)"
          echo "  --key-type TYPE       Set the key type (default: $KEY_TYPE)"
          echo "  --expiration TIME     Set the expiration time (default: $EXPIRATION)"
          echo "  --gnupg-home DIR      Set the GnuPG home directory (default: $GNUPGHOME)"
          echo "  --public-key-dest DIR Set the public key export destination (default: $PUBLIC_KEY_DEST)"
          echo "  --passphrase-file FILE Export the certify passphrase to the specified file"
          echo "  --admin-pin-file FILE Export the admin pin to the specified file"
          echo "  --user-pin-file FILE Export the user pin to the specified file"
          echo "  --passphrase-file FILE Export the certify passphrase to the specified file"
          echo "  --help                Display this help message"
          exit 1
      }

      while [[ "$#" -gt 0 ]]; do
          case "$1" in
              --identity)
                  IDENTITY="$2"
                  shift 2
                  ;;
              --key-type)
                  KEY_TYPE="$2"
                  shift 2
                  ;;
              --expiration)
                  EXPIRATION="$2"
                  shift 2
                  ;;
              --gnupg-home)
                  GNUPGHOME="$2"
                  shift 2
                  ;;
              --public-key-dest)
                  PUBLIC_KEY_DEST="$2"
                  shift 2
                  ;;
              --passphrase-file)
                  PASSPHRASE_FILE="$2"
                  shift 2
                  ;;
              --admin-pin-file)
                  ADMIN_PIN_FILE="$2"
                  shift 2
                  ;;
              --user-pin-file)
                  USER_PIN_FILE="$2"
                  shift 2
                  ;;
              --help)
                  usage
                  ;;
              *)
                  echo "Unknown option: $1"
                  usage
                  ;;
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
          chmod 600 "$PASSPHRASE_FILE"  # Restrict access to the passphrase file
      fi

      echo "Creating certify key"

      echo $CERTIFY_PASS | gpg --batch --passphrase-fd 0 --quick-generate-key $IDENTITY $KEY_TYPE cert never

      KEYID=$(gpg -k --with-colons $IDENTITY | awk -F: '/^pub:/ { print $5; exit }')
      KEYFP=$(gpg -k --with-colons $IDENTITY | awk -F: '/^fpr:/ { print $10; exit }')

      echo "Creating subkeys"

      for SUBKEY in sign encrypt auth ; do
          echo $CERTIFY_PASS | gpg --batch --pinentry-mode=loopback --passphrase-fd 0 \
              --quick-add-key $KEYFP $KEY_TYPE $SUBKEY $EXPIRATION
      done

      gpg -K

      echo "Creating backup keys"

      echo $CERTIFY_PASS | gpg --output "$GNUPGHOME/$KEYID-Certify.key" \
          --batch --pinentry-mode=loopback --passphrase-fd 0 \
          --armor --export-secret-keys "$KEYID"

      echo $CERTIFY_PASS | gpg --output "$GNUPGHOME/$KEYID-Subkeys.key" \
          --batch --pinentry-mode=loopback --passphrase-fd 0 \
          --armor --export-secret-subkeys "$KEYID"

      echo "Exporting public key"

      gpg --output $PUBLIC_KEY_DEST/$KEYID-$(date +%F).asc \
          --armor --export "$KEYID"

      sudo chmod 0444 $PUBLIC_KEY_DEST/*.asc

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
  };
in {
  options = {
    modules = {
      security = {
        yubikey = {
          enable = lib.mkEnableOption "Enable yubikey" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.yubikey.enable) {
    boot = {
      initrd = {
        luks = {
          yubikeySupport = cfg.yubikey.enable;
        };
      };
    };
    hardware = {
      gpgSmartcards = {
        inherit (cfg.yubikey) enable;
      };
    };
    services = {
      pcscd = {
        inherit (cfg.yubikey) enable;
      };
      udev = {
        packages = [pkgs.yubikey-personalization];
      };
    };
    programs = {
      yubikey-touch-detector = {
        inherit (cfg.yubikey) enable;
      };
      ssh = {
        startAgent = false;
      };
      gnupg = {
        agent = {
          inherit (cfg.yubikey) enable;
        };
      };
    };
    services = {
      yubikey-agent = {
        inherit (cfg.yubikey) enable;
      };
    };
    environment = {
      systemPackages = [
        pkgs.yubikey-manager
        pkgs.yubikey-manager-qt
        pkgs.yubikey-personalization
        pkgs.yubikey-personalization-gui
        pkgs.yubico-piv-tool
        pkgs.yubioath-flutter
        yubikeyGuide
        yubikey-gpg-setup
      ];
    };
    system = {
      activationScripts = {
        yubikey-guide = let
          homeDir = "/home/${config.modules.users.name}/";
          desktopDir = homeDir + "Desktop/";
          documentsDir = homeDir + "Documents/";
        in ''
          mkdir -p ${desktopDir} ${documentsDir}
          chown ${config.modules.users.name} ${homeDir} ${desktopDir} ${documentsDir}
          ln -sf ${yubikeyGuide}/share/applications/yubikey-guide.desktop ${desktopDir}
          ln -sfT ${inputs.yubikey-guide} /home/${config.modules.users.name}/Documents/YubiKey-Guide
        '';
      };
    };
  };
}
