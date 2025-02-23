final: prev: {
  cymenixos-scripts = let
    build-system = prev.writeShellApplication {
      name = "build-system";
      runtimeInputs = [prev.nix-output-monitor];
      text = ''
        nom build .#nixosConfigurations.nixos.config.system.build.toplevel --show-trace
      '';
    };
    build-offline-system = prev.writeShellApplication {
      name = "build-offline-system";
      runtimeInputs = [prev.nix-output-monitor];
      text = ''
        nom build .#nixosConfigurations.offline.config.system.build.toplevel --show-trace
      '';
    };
    build-iso = prev.writeShellApplication {
      name = "build-iso";
      runtimeInputs = [prev.nix-output-monitor];
      text = ''
        nom build .#nixosConfigurations.iso.config.system.build.isoImage --show-trace
      '';
    };
    build-offline-iso = prev.writeShellApplication {
      name = "build-offline-iso";
      runtimeInputs = [prev.nix-output-monitor];
      text = ''
        nom build .#nixosConfigurations.offline-iso.config.system.build.isoImage --show-trace
      '';
    };
    build-test-iso = prev.writeShellApplication {
      name = "build-test-iso";
      runtimeInputs = [prev.nix-output-monitor];
      text = ''
        nom build .#nixosConfigurations.test.config.system.build.isoImage --show-trace
      '';
    };
    build-test-offline-iso = prev.writeShellApplication {
      name = "build-test-offline-iso";
      runtimeInputs = [prev.nix-output-monitor];
      text = ''
        nom build .#nixosConfigurations.offline-test.config.system.build.isoImage --show-trace
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
    cymenixos-install-offline = prev.writeShellApplication {
      name = "cymenixos-install-offline";
      runtimeInputs = [cymenixos-install];
      text = ''
        cymenixos-install "$FLAKE#offline"
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
      excludeShellChecks = ["SC2086"];
      text = ''
        ISO="result-iso"
        DISK="vm.qcow2"
        CPU=8
        MEMORY=16G
        USB_ARGS=""
        HOSTBUS=""
        HOSTADDR=""

        usage() {
          echo "Usage: $0 [OPTIONS]"
          echo ""
          echo "Options:"
          echo "  --cpu <num>       Set the number of CPU cores (default: 8)"
          echo "  --memory <size>   Set the memory allocated to VM (default: 16G)"
          echo "  --hostbus <num>   USB passthrough: specify the USB bus number"
          echo "  --hostaddr <num>  USB passthrough: specify the USB device address"
          echo "  --help            Show this help message and exit"
          echo ""
          echo "Example:"
          echo "  $0 --cpu 4 --memory 8G --hostbus 1 --hostaddr 2"
          echo ""
          echo "To find HOSTBUS and HOSTADDR, run 'lsusb'"
          exit 0
        }

        while [[ $# -gt 0 ]]; do
          case "$1" in
            --cpu)
              CPU="$2"
              shift 2
              ;;
            --memory)
              MEMORY="$2"
              shift 2
              ;;
            --hostbus)
              HOSTBUS="$2"
              PADDED_HOSTBUS=$(printf "%03d" "$HOSTBUS")
              shift 2
              ;;
            --hostaddr)
              HOSTADDR="$2"
              PADDED_HOSTADDR=$(printf "%03d" "$HOSTADDR")
              shift 2
              ;;
            --help)
              usage
              ;;
            *)
              echo "Unknown argument: $1"
              usage
              ;;
          esac
        done

        if fd --type file --has-results 'nixos-.*\.iso' result/iso 2>/dev/null; then
          echo "Symlinking the existing ISO image for QEMU:"
          ln -sfv result/iso/nixos-*.iso "$ISO"
        else
          echo "No ISO file exists to run. Please build one first, example:"
          echo "\${build-iso}/bin/build-iso"
          exit 1
        fi

        if [ ! -f "$DISK" ]; then
          echo "Disk not found. Creating a new disk and booting from ISO for installation..."
          qemu-img create -f qcow2 "$DISK" 64G
        fi

        if [[ -n "$HOSTBUS" && -n "$HOSTADDR" ]]; then
          USB_PATH="/dev/bus/usb/$PADDED_HOSTBUS/$PADDED_HOSTADDR"
          echo "Passing through USB device at bus $HOSTBUS, address $HOSTADDR"

          if [ -e "$USB_PATH" ]; then
            echo "Applying chmod to allow access..."
            sudo chmod 666 "$USB_PATH"
            USB_ARGS="-usb -device qemu-xhci -device usb-host,hostbus=$HOSTBUS,hostaddr=$HOSTADDR"
          else
            echo "Warning: USB device $USB_PATH not found! Skipping USB passthrough."
          fi
        else
          echo "Not passing through any host devices"
          echo "It is recommended to passthrough the USB device"
          echo "eg. '$0 --hostbus <HOSTBUS> --hostaddr <HOSTADDR>'"
          echo "where HOSTBUS and HOSTADDR can be identified via 'lsusb'"
          echo "If this fails, ensure your user has the 'usb' group or use 'chmod 666' on the device"
        fi

        LD_LIBRARY_PATH="${prev.pipewire.jack}/lib" qemu-kvm \
          -smp "$CPU" \
          -m "$MEMORY" \
          -drive file="$DISK",format=qcow2,if=virtio,id=disk,index=0 \
          -drive file="$ISO",format=raw,if=none,media=cdrom,id=cd,index=1,readonly=on \
          -device ahci,id=achi0 \
          -device virtio-vga-gl -display sdl,gl=on,show-cursor=off \
          -device ide-cd,bus=achi0.0,drive=cd,id=cd1 \
          -device intel-hda \
          -device hda-duplex,audiodev=audio0 \
          -audiodev pipewire,id=audio0 \
          -boot order=cd,menu=on \
          $USB_ARGS \
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
    prev.symlinkJoin {
      name = "cymenixos-scripts";
      paths = [
        build-system
        build-offline-system
        build-iso
        build-offline-iso
        build-test-iso
        build-test-offline-iso
        write-iso-to-device
        cymenixos-install
        cymenixos-install-offline
        qemu-run-iso
        copyro
        btrfs-swap-resume-offset
      ];
    };
}
