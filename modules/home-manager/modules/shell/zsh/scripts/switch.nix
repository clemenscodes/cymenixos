{pkgs, ...}: let
  write-grub-menu-entries = pkgs.writeShellApplication {
    name = "write-grub-menu-entries";
    text = ''
      BOOT_CONFIG="$OUT/boot.json"
      GRUB_CFG="/boot/grub/grub.cfg"
      BACKUP_GRUB_CFG="$GRUB_CFG.bak"

      cp "$GRUB_CFG" "$BACKUP_GRUB_CFG"

      KERNEL_PATH=$(jq -r '.["org.nixos.bootspec.v1"].kernel' "$BOOT_CONFIG")
      INITRD_PATH=$(jq -r '.["org.nixos.bootspec.v1"].initrd' "$BOOT_CONFIG")
      INIT_SCRIPT_PATH=$(jq -r '.["org.nixos.bootspec.v1"].init' "$BOOT_CONFIG")
      KERNEL_PARAMS=$(jq -r '.["org.nixos.bootspec.v1"].kernelParams | join(" ")' "$BOOT_CONFIG")
      LABEL=$(jq -r '.["org.nixos.bootspec.v1"].label' "$BOOT_CONFIG")

      if [ -z "$KERNEL_PATH" ] || [ -z "$INITRD_PATH" ] || [ -z "$INIT_SCRIPT_PATH" ] || [ -z "$LABEL" ]; then
        echo "Error: Some necessary fields are missing from the boot.json."
        exit 1
      fi

      CURRENT_GEN=$(grep -oP 'menuentry "NixOS - Configuration \K\d+' "$GRUB_CFG" | sort -n | tail -n 1)

      if [ -z "$CURRENT_GEN" ]; then
        NEW_GEN=1
      else
        NEW_GEN=$((CURRENT_GEN + 1))
      fi

      NEW_ENTRY=$(cat <<EOF
      menuentry "NixOS - Configuration $NEW_GEN ($LABEL)" --class nixos --unrestricted {
          linux $KERNEL_PATH init=$INIT_SCRIPT_PATH $KERNEL_PARAMS
          initrd $INITRD_PATH
      }
      EOF
      )

      SUBMENU_POS=$(grep -n 'submenu "NixOS - All configurations" --class submenu {' "$GRUB_CFG" | cut -d: -f1)

      if [ -z "$SUBMENU_POS" ]; then
        echo "Error: Could not find the submenu section in the grub.cfg."
        exit 1
      fi

      head -n "$SUBMENU_POS" "$BACKUP_GRUB_CFG" > "$BACKUP_GRUB_CFG.new"
      printf "%s\n" "$NEW_ENTRY" >> "$BACKUP_GRUB_CFG.new"
      tail -n +$((SUBMENU_POS + 1)) "$BACKUP_GRUB_CFG" >> "$BACKUP_GRUB_CFG.new"

      mv "$BACKUP_GRUB_CFG.new" "$GRUB_CFG"
    '';
  };
in
  pkgs.writeShellApplication {
    name = "switch";
    text = ''
      SWITCH_SCRIPT="$FLAKE/result/bin/switch-to-configuration"
      TMP_SCRIPT=$(mktemp)
      cp "$SWITCH_SCRIPT" "$TMP_SCRIPT"
      sed -i "s|export INSTALL_BOOTLOADER=.*|export INSTALL_BOOTLOADER='${write-grub-menu-entries}/bin/write-grub-menu-entries'|" "$TMP_SCRIPT"
      sudo "$TMP_SCRIPT" switch "$@"
      rm "$TMP_SCRIPT"
    '';
  }
