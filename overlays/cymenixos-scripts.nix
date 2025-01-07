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
    btrfs-swap-resume-offset = prev.writeShellApplication {
      name = "btrfs-swap-resume-offset";
      runtimeInputs = [prev.btrfs-progs];
      text = ''
        btrfs inspect-internal map-swapfile -r /swap/swapfile
      '';
    };
    cymenixos-install = prev.writeShellApplication {
      name = "cymenixos-install";
      runtimeInputs = [prev.disko];
      text = ''
        usage() {
          echo "Usage: $0 [--dry-run] [--help] [config]"
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
          disko-install --dry-run --mode format -f "$CONFIG" --disk main "$DEVICE"
        else
          echo "Running in actual mode (requires sudo)..."
          sudo disko-install --mode format -f "$CONFIG" --disk main "$DEVICE"
        fi
      '';
    };
    qemu-run-iso = prev.writeShellApplication {
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
          echo
        else
          echo "No iso file exists to run, please build one first, example:"
          echo "  nix build -L .#nixosConfigurations.airgap-boot.config.system.build.isoImage"
          exit
        fi

        DISK="vm.qcow2"

        # Create the disk if it doesn't exist
        if [ ! -f "$DISK" ]; then
            echo "Disk not found. Creating a new disk and booting from ISO for installation..."
            qemu-img create -f qcow2 "$DISK" 64G
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
        ln -s ${cymenixos-install}/bin/cymenixos-install $out/bin
        ln -s ${qemu-run-iso}/bin/qemu-run-iso $out/bin
        ln -s ${copyro}/bin/copyro $out/bin
        ln -s ${btrfs-swap-resume-offset}/bin/btrfs-swap-resume-offset $out/bin
      '';
    };
}
