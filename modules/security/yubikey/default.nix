{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  inherit (config.modules.boot.impermanence) persistPath;
  cfg = config.modules.security;
  homeDirectory = "/home/${config.modules.users.name}";
  viewYubikeyGuide = pkgs.writeShellScriptBin "view-yubikey-guide" ''
    exec ${pkgs.glow}/bin/glow -p "${inputs.yubikey-guide}/README.md"
  '';
  shortcut = pkgs.makeDesktopItem {
    name = "yubikey-guide";
    icon = "${pkgs.yubioath-flutter}/share/icons/com.yubico.yubioath.png";
    desktopName = "drduh's YubiKey Guide";
    genericName = "Guide to using YubiKey for GnuPG and SSH";
    comment = "Open the guide in a reader program";
    categories = ["Documentation"];
    terminal = true;
    exec = "${viewYubikeyGuide}/bin/view-yubikey-guide";
  };
  yubikeyGuide = pkgs.symlinkJoin {
    name = "yubikey-guide";
    paths = [viewYubikeyGuide shortcut];
  };
  yubikey-pubkey-url = pkgs.writeShellApplication {
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
      url $PUBLIC_KEY_URL
      quit
      EOF

      echo "Public key URL set successfully!"
    '';
  };
  yubikey-gpg-setup = pkgs.writeShellApplication {
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
              --key-fp-file) KEYID_FILE="$2" shift 2 ;;
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

      echo $CERTIFY_PASS | gpg --output "$PRIVATE_KEY_DEST/$KEYID-Certify.key" \
          --batch --pinentry-mode=loopback --passphrase-fd 0 \
          --armor --export-secret-keys "$KEYID"

      echo $CERTIFY_PASS | gpg --output "$SUBKEYS_DEST/$KEYID-Subkeys.key" \
          --batch --pinentry-mode=loopback --passphrase-fd 0 \
          --armor --export-secret-subkeys "$KEYID"

      echo "Exporting public key"

      gpg --output $PUBLIC_KEY_DEST/$KEYID-$(date +%F).asc \
          --armor --export "$KEYID"

      sudo chmod 0444 $PUBLIC_KEY_DEST/*.asc

      echo "Deleting master secret key from local keyring..."
      gpg --batch --yes --delete-secret-keys "$KEYFP"

      echo "Re-importing the public key for verification..."
      gpg --import "$PUBLIC_KEY_DEST/$KEYID-$(date +%F).asc"

      echo "Re-importing the subkeys..."
      echo $CERTIFY_PASS | gpg --batch --pinentry-mode=loopback --passphrase-fd 0 --import "$SUBKEYS_DEST/$KEYID-Subkeys.key"

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
  yubikey-up = let
    yubikeyIds = lib.concatStringsSep " " (
      lib.mapAttrsToList (name: id: "[${name}]=\"${builtins.toString id}\"") cfg.yubikey.pam.identifiers
    );
  in
    pkgs.writeShellApplication {
      name = "yubikey-up";
      runtimeInputs = [pkgs.yubikey-manager];
      text = ''
        serial=$(ykman list | awk '{print $NF}')
        # If it got unplugged before we ran, just don't bother
        if [ -z "$serial" ]; then
          # FIXME(yubikey): Warn probably
          exit 0
        fi

        declare -A serials=(${yubikeyIds})

        key_name=""
        for key in "''${!serials[@]}"; do
          if [[ $serial == "''${serials[$key]}" ]]; then
            key_name="$key"
          fi
        done

        if [ -z "$key_name" ]; then
          echo WARNING: Unidentified yubikey with serial "$serial" . Won\'t link an SSH key.
          exit 0
        fi

        echo "Creating links to ${homeDirectory}/id_$key_name"
        ln -sf "${homeDirectory}/.ssh/id_$key_name" ${homeDirectory}/.ssh/id_yubikey
        ln -sf "${homeDirectory}/.ssh/id_$key_name.pub" ${homeDirectory}/.ssh/id_yubikey.pub
      '';
    };
  yubikey-down = pkgs.writeShellApplication {
    name = "yubikey-down";
    text = ''
      rm ${homeDirectory}/.ssh/id_yubikey
      rm ${homeDirectory}/.ssh/id_yubikey.pub
    '';
  };
in {
  options = {
    modules = {
      security = {
        yubikey = {
          enable = lib.mkEnableOption "Enable yubikey" // {default = false;};
          pam = {
            enable = lib.mkEnableOption "Enable yubikey PAM" // {default = false;};
            u2f-mappings = lib.mkOption {
              default = [];
              type = lib.types.listOf lib.types.str;
              description = "The list of u2f mappings for pam auth";
              example = lib.literalExample ''
                [
                  ":<KeyHandle1>,<UserKey1>,<CoseType1>,<Options1>"
                  ":<KeyHandle2>,<UserKey2>,<CoseType2>,<Options2>"
                ]
              '';
            };
            identifiers = lib.mkOption {
              default = {};
              type = lib.types.attrsOf lib.types.int;
              description = "Attrset of Yubikey serial numbers. NOTE: Yubico's 'Security Key' products do not use unique serial number therefore, the scripts in this module are unable to distinguish between multiple 'Security Key' devices and instead will detect a Security Key serial number as the string \"[FIDO]\". This means you can only use a single Security Key but can still mix it with YubiKey 4 and 5 devices.";
              example = lib.literalExample ''
                {
                  foo = 12345678;
                  bar = 87654321;
                  baz = "[FIDO]";
                }
              '';
            };
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.yubikey.enable) {
    boot = {
      initrd = {
        kernelModules = ["vfat" "nls_cp437" "nls_iso8859-1" "usbhid"];
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
      yubikey-agent = {
        inherit (cfg.yubikey) enable;
      };
      udev = {
        packages = [pkgs.yubikey-personalization];
        extraRules = ''
          # ACTION=="remove",\
          #  ENV{ID_BUS}=="usb",\
          #  ENV{ID_MODEL_ID}=="0407",\
          #  ENV{ID_VENDOR_ID}=="1050",\
          #  ENV{ID_VENDOR}=="Yubico",\
          #  RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
          #
          # Link/unlink ssh key on yubikey add/remove
          # SUBSYSTEM=="usb", ACTION=="add", ATTR{idVendor}=="1050", RUN+="${lib.getBin yubikey-up}/bin/yubikey-up"
          # NOTE: Yubikey 4 has a ID_VENDOR_ID on remove, but not Yubikey 5 BIO, whereas both have a HID_NAME.
          # Yubikey 5 HID_NAME uses "YubiKey" whereas Yubikey 4 uses "Yubikey", so matching on "Yubi" works for both
          # SUBSYSTEM=="hid", ACTION=="remove", ENV{HID_NAME}=="Yubico Yubi*", RUN+="${lib.getBin yubikey-down}/bin/yubikey-down"
        '';
      };
    };
    security = {
      pam = lib.mkIf cfg.yubikey.pam.enable {
        services = {
          login = {
            u2fAuth = true;
          };
          sudo = {
            u2fAuth = true;
            sshAgentAuth = cfg.ssh.enable;
          };
        };
        u2f = {
          inherit (cfg.yubikey.pam) enable;
          settings = {
            cue = true;
            interactive = true;
            debug = true;
            authFile = pkgs.writeText "u2f-mappings" (lib.concatStrings [config.modules.users.name] ++ cfg.u2f-mappings);
          };
        };
        # yubico = {
        #   inherit (cfg.yubikey.pam) enable;
        #   debug = true;
        #   mode = "challenge-response";
        #   control = "sufficient";
        #   # id = lib.mapAttrsToList (name: id: "${builtins.toString id}") cfg.yubikey.pam.identifiers;
        # };
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
    environment = {
      systemPackages = [
        pkgs.yubikey-manager
        pkgs.yubioath-flutter
        pkgs.yubico-piv-tool
        pkgs.yubico-pam
        pkgs.pam_u2f
        yubikeyGuide
        yubikey-gpg-setup
        yubikey-up
        yubikey-down
        yubikey-pubkey-url
      ];
      persistence = {
        "${persistPath}" = {
          users = {
            ${config.modules.users.user} = {
              directories = [
                ".config/Yubico"
                ".local/share/com.yubico.authenticator"
              ];
            };
          };
        };
      };
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
