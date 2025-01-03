{pkgs, ...}: {
  build-system = pkgs.writeShellApplication {
    name = "build-system";
    runtimeInputs = [pkgs.nix-output-monitor];
    text = ''
      nom build .#nixosConfigurations.nixos.config.system.build.toplevel --show-trace
    '';
  };
  build-iso = pkgs.writeShellApplication {
    name = "build-iso";
    runtimeInputs = [pkgs.nix-output-monitor];
    text = ''
      nom build .#nixosConfigurations.iso.config.system.build.isoImage --show-trace
    '';
  };
  install-cymenixos = pkgs.writeShellApplication {
    name = "install-cymenixos";
    runtimeInputs = [pkgs.disko];
    text = ''
      usage() {
        echo "Usage: $0 [--dry-run] [config]"
        echo "  --dry-run    Run in dry-run mode"
        echo "  [config]     Nix flake output for disko-install (default: $FLAKE#nixos)"
        exit 1
      }

      error() {
        echo "Error: Invalid config or $1 not found."
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

      if [ "$#" -lt 1 ]; then
        usage
      fi

      DRY_RUN=false
      if [ "$#" -ge 1 ] && [ "$1" == "--dry-run" ]; then
        DRY_RUN=true
        shift
      fi

      MODE="format"

      CONFIG=''${1:-$FLAKE#nixos}
      DEVICE=$(resolve_config_value "$CONFIG" "config.modules.disk.device")

      if [ "$DRY_RUN" == true ]; then
        echo "Running in dry-run mode..."
        disko-install --dry-run --mode "$MODE" -f "$CONFIG" --disk main "$DEVICE"
      else
        echo "Running in actual mode (requires sudo)..."
        sudo disko-install --mode "$MODE" -f "$CONFIG" --disk main "$DEVICE"
      fi
    '';
  };
  qemu-run-iso = pkgs.writeShellApplication {
    name = "qemu-run-iso";
    runtimeInputs = [
      pkgs.fd
      pkgs.qemu_kvm
      pkgs.pipewire
      pkgs.pipewire.jack
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
      LD_LIBRARY_PATH="${pkgs.pipewire.jack}/lib" qemu-kvm \
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
  copyro = pkgs.writeShellApplication {
    name = "copyro";
    text = ''
      SOURCE_DIR=$1
      DEST_DIR=$2

      if [ ! -d "$DEST_DIR" ]; then
        echo "Destination does not exist. Starting copy process."

        copy_directory() {
          local src
          local dest

          src="$1"
          dest="$2"

          mkdir -p "$dest"

          for item in "$src"/*; do
            [ -e "$item" ] || continue
            local dest_item
            dest_item="$dest/$(basename "$item")"
            if [ -d "$item" ]; then
              copy_directory "$item" "$dest_item"
            elif [ -f "$item" ]; then
              cp "$item" "$dest_item"
            fi
          done
        }

        copy_directory "$SOURCE_DIR" "$DEST_DIR"

        find "$DEST_DIR" -type d -exec chmod 755 {} \;
        find "$DEST_DIR" -type f -exec chmod 644 {} \;

        echo "Copy process completed successfully."
      else
        echo "Destination already exists. No action taken."
      fi
    '';
  };
}
