final: prev: {
  cymenixos-scripts = let
    build-system = prev.writeShellApplication {
      name = "build-system";
      runtimeInputs = [prev.nix-output-monitor];
      text = ''
        nom build .#nixosConfigurations.nixos.config.system.build.toplevel --show-trace
      '';
    };
    build-iso = prev.writeShellApplication {
      name = "build-iso";
      runtimeInputs = [prev.nix-output-monitor];
      text = ''
        nom build .#nixosConfigurations.iso.config.system.build.isoImage --show-trace
      '';
    };
    build-test-iso = prev.writeShellApplication {
      name = "build-test-iso";
      runtimeInputs = [prev.nix-output-monitor];
      text = ''
        nom build .#nixosConfigurations.test.config.system.build.isoImage --show-trace
      '';
    };
    write-iso-to-device = prev.writeShellApplication rec {
      name = "write-iso-to-device";
      runtimeInputs = [prev.nix-output-monitor];
      text = ''
        usage() {
          echo "Usage: ${name} [--help] DEVICE"
          echo "  --help  Show this help"
          echo "  DEVICE  The device to write the iso to (e.g: /dev/sdc)"
        }

        if [ "$#" -ge 1 ] && [ "$1" = "--help" ]; then
          usage
          exit 0
        fi

        if [ "$#" -ge 1 ]; then
          DEVICE="$1"
        else
          echo "Error: no device was specified"
          echo "Insert USB and run lsblk to see available devices"
          exit 1
        fi

        echo "Building ISO..."

        ${build-iso}/bin/build-iso

        ISO="result-iso"

        if fd --type file --has-results 'nixos-.*\.iso' result/iso 2> /dev/null; then
          echo "Symlinking the existing iso image for writing to a device"
          ln -sfv result/iso/nixos-*.iso "$ISO"
        else
          echo "No iso file exists to run, please build one first, example:"
          echo "${build-iso}/bin/build-iso"
          exit
        fi

        echo "Installing $ISO to $DEVICE"
        sudo dd bs=4M status=progress oflag=direct conv=fsync if="$ISO" of="$DEVICE"
      '';
    };
    btrfs-swap-resume-offset = prev.writeShellApplication {
      name = "btrfs-swap-resume-offset";
      runtimeInputs = [prev.btrfs-progs];
      text = ''
        btrfs inspect-internal map-swapfile -r /swap/swapfile
      '';
    };
    cymenixos-install = prev.writeShellApplication rec {
      name = "cymenixos-install";
      runtimeInputs = [prev.disko];
      text = ''
        usage() {
          echo "Usage: ${name} [--dry-run] [--help] [config]"
          echo "  --dry-run    Run in dry-run mode"
          echo "  --help       Show this help"
          echo "  [config]     Nix flake output for disko-install (default: $FLAKE#nixos)"
        }

        error() {
          echo "Error: Invalid config or $1 not found."
          usage
          exit 1
        }

        resolve_config_value() {
          local config
          local path
          local full_uri
          local value

          config=$1
          path=$2
          full_uri=$(echo "$config" | awk -v insert="nixosConfigurations." -F'#' '{print $1 "#" insert $2}')
          value=$(nix eval "$full_uri.$path" 2>/dev/null || error "$path")
          value=$(echo "$value" | tr -d '"')

          echo "$value"
        }

        if [ "$#" -ge 1 ] && [ "$1" = "--help" ]; then
          usage
          exit 0
        fi

        DRY_RUN=false
        if [ "$#" -ge 1 ] && [ "$1" == "--dry-run" ]; then
          DRY_RUN=true
          shift
        fi

        CONFIG="$FLAKE#nixos"

        if [ "$#" -ge 1 ]; then
          CONFIG="$1"
        fi

        DEVICE=$(resolve_config_value "$CONFIG" "config.modules.disk.device")

        if [ "$DRY_RUN" == true ]; then
          echo "Running in dry-run mode..."
          echo "Would run disko-install --dry-run --mode format -f $CONFIG --disk main $DEVICE"
          disko-install --dry-run --mode format -f "$CONFIG" --disk main "$DEVICE"
        else
          echo "Running in actual mode (requires sudo)..."
          echo "Running sudo disko-install --mode format -f $CONFIG --disk main $DEVICE"
          sudo disko-install --mode format -f "$CONFIG" --disk main "$DEVICE"
        fi
      '';
    };
    qemu-run-iso = prev.writeShellApplication rec {
      name = "qemu-run-iso";
      runtimeInputs = [
        prev.fd
        prev.qemu_kvm
        prev.pipewire
        prev.pipewire.jack
      ];

      text = ''
        ISO="result-iso"

        if fd --type file --has-results 'nixos-.*\.iso' result/iso 2> /dev/null; then
          echo "Symlinking the existing iso image for qemu:"
          ln -sfv result/iso/nixos-*.iso "$ISO"
        else
          echo "No iso file exists to run, please build one first, example:"
          echo "${build-iso}/bin/build-iso"
          exit
        fi

        DISK="vm.qcow2"

        # Create the disk if it doesn't exist
        if [ ! -f "$DISK" ]; then
          echo "Disk not found. Creating a new disk and booting from ISO for installation..."
          qemu-img create -f qcow2 "$DISK" 64G
        fi

        if [ "$#" = 0 ]; then
          echo "Not passing through any host devices"
          echo "It is recommended to passthrough the USB device"
          echo "eg. '${name} -usb -device qemu-xhci -device usb-host,hostbus=<HOSTBUS>,hostaddr=<HOSTADDR>'"
          echo "where HOSTBUS and HOSTADDR can be identified via 'lsusb'"
          echo "If this fails, ensure your user has the group usb"
          echo "Otherwise you may run 'chmod 666 /dev/bus/usb/<HOSTBUS>/<HOSTADDR>' to grant access to the USB device"
        fi

        # Always try to boot from disk first, fallback to ISO if disk fails
        LD_LIBRARY_PATH="${prev.pipewire.jack}/lib" qemu-kvm \
          -smp 8 \
          -m 16G \
          -drive file="$DISK",format=qcow2,if=virtio,id=disk,index=0 \
          -drive file="$ISO",format=raw,if=none,media=cdrom,id=cd,index=1,readonly=on \
          -device ahci,id=achi0 \
          -device virtio-vga-gl -display sdl,gl=on,show-cursor=off \
          -device ide-cd,bus=achi0.0,drive=cd,id=cd1 \
          -device intel-hda \
          -device hda-duplex,audiodev=audio0 \
          -audiodev pipewire,id=audio0 \
          -boot order=cd,menu=on \
          "$@"
      '';
    };
    create-gpg-keys = prev.writeShellApplication {
      name = "create-gpg-keys";
      runtimeInputs = [prev.gnupg];
      text = ''
        IDENTITY="YubiKey"
        KEY_TYPE="rsa4096"
        EXPIRATION="2y"
        GNUPGHOME="''${GNUPGHOME:-$HOME/.gnupg}"
        PUBLIC_KEY_DEST="''${GNUPGHOME}"
        PASSPHRASE_FILE=""

        usage() {
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --identity NAME       Set the identity name (default: $IDENTITY)"
            echo "  --key-type TYPE       Set the key type (default: $KEY_TYPE)"
            echo "  --expiration TIME     Set the expiration time (default: $EXPIRATION)"
            echo "  --gnupg-home DIR      Set the GnuPG home directory (default: $GNUPGHOME)"
            echo "  --public-key-dest DIR Set the public key export destination (default: $PUBLIC_KEY_DEST)"
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

        echo "$CERTIFY_PASS" | gpg --batch --passphrase-fd 0 --quick-generate-key "$IDENTITY" "$KEY_TYPE" cert never

        KEYID=$(gpg -k --with-colons "$IDENTITY" | awk -F: '/^pub:/ { print $5; exit }')
        KEYFP=$(gpg -k --with-colons "$IDENTITY" | awk -F: '/^fpr:/ { print $10; exit }')

        echo "Creating subkeys"

        for SUBKEY in sign encrypt auth ; do
            echo "$CERTIFY_PASS" | gpg --batch --pinentry-mode=loopback --passphrase-fd 0 \
                --quick-add-key "$KEYFP" "$KEY_TYPE" "$SUBKEY" "$EXPIRATION"
        done

        gpg -K

        echo "Creating backup keys"

        echo "$CERTIFY_PASS" | gpg --output "$GNUPGHOME/$KEYID-Certify.key" \
            --batch --pinentry-mode=loopback --passphrase-fd 0 \
            --armor --export-secret-keys "$KEYID"

        echo "$CERTIFY_PASS" | gpg --output "$GNUPGHOME/$KEYID-Subkeys.key" \
            --batch --pinentry-mode=loopback --passphrase-fd 0 \
            --armor --export-secret-subkeys "$KEYID"

        echo "Exporting public key"

        gpg --output "$PUBLIC_KEY_DEST/$KEYID-$(date +%F).asc" \
            --armor --export "$KEYID"

        sudo chmod 0444 "$PUBLIC_KEY_DEST"/*.asc
      '';
    };
    copyro = prev.writeShellApplication {
      name = "copyro";
      text = ''
        SOURCE_DIR=$1
        DEST_DIR=$2

        # Check if the destination directory exists and if writable
        if [ ! -d "$DEST_DIR" ]; then
          echo "Destination does not exist. Starting copy process."

          copy_directory() {
            local src
            local dest

            src="$1"
            dest="$2"

            # Attempt to create the directory and handle permission error
            if ! mkdir -p "$dest"; then
              echo "Permission denied while creating $dest. Exiting successfully."
              exit 0
            fi

            for item in "$src"/*; do
              [ -e "$item" ] || continue
              local dest_item
              dest_item="$dest/$(basename "$item")"
              if [ -d "$item" ]; then
                copy_directory "$item" "$dest_item"
              elif [ -f "$item" ]; then
                if ! cp "$item" "$dest_item"; then
                  echo "Permission denied while copying $item. Skipping."
                fi
              fi
            done
          }

          copy_directory "$SOURCE_DIR" "$DEST_DIR"

          find "$DEST_DIR" -type d -exec chmod 755 {} \;
          find "$DEST_DIR" -type f -exec chmod 644 {} \;

          echo "Copy process completed successfully."
        else
          if [ ! -w "$DEST_DIR" ]; then
            echo "Destination already exists but permission denied. Exiting successfully."
            exit 0
          fi
          echo "Destination already exists. No action taken."
        fi
      '';
    };
  in
    prev.stdenv.mkDerivation {
      name = "cymenixos-scripts";
      phases = "installPhase";
      installPhase = ''
        mkdir -p $out/bin
        ln -s ${build-system}/bin/build-system $out/bin
        ln -s ${build-iso}/bin/build-iso $out/bin
        ln -s ${build-test-iso}/bin/build-test-iso $out/bin
        ln -s ${write-iso-to-device}/bin/write-iso-to-device $out/bin
        ln -s ${cymenixos-install}/bin/cymenixos-install $out/bin
        ln -s ${qemu-run-iso}/bin/qemu-run-iso $out/bin
        ln -s ${copyro}/bin/copyro $out/bin
        ln -s ${btrfs-swap-resume-offset}/bin/btrfs-swap-resume-offset $out/bin
        ln -s ${create-gpg-keys}/bin/create-gpg-keys $out/bin
      '';
    };
}
