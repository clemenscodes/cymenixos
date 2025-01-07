{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
  efiPath = config.boot.loader.efi.efiSysMountPoint;
  modules = "part_gpt luks2 mdraid1x cryptodisk gcry_rijndael gcry_sha256 gcry_sha512 argon2 btrfs zfs true";
  root = "(crypto0)";
  stub = "${efiPath}/EFI/BOOT/BOOTX64.EFI";
  efiPrefix = "${root}${efiPath}/grub";
  biosPrefix = "${root}/boot/grub";
  inherit (lib) escapeShellArg;
in {
  config = lib.mkIf (cfg.enable && cfg.boot.enable && !cfg.users.isIso) {
    boot = {
      loader = lib.mkIf (!cfg.boot.secureboot.enable) {
        grub = {
          enableCryptodisk = true;
          extraGrubInstallArgs = ["--efi-directory=${config.boot.loader.efi.efiSysMountPoint}" "--modules=${modules}"];
          extraInstallCommands = ''
            grub_tmp=$(mktemp -d -t grub.conf.XXXXXXXX)

            trap 'rm -rf -- "$grub_tmp"' EXIT

            cat <<EOS >"$grub_tmp/grub.cfg"
              cryptomount -u $(${pkgs.utillinux}/bin/blkid -o value -s UUID ${escapeShellArg config.boot.initrd.luks.devices.${cfg.disk.luksDisk}.device})
              set root=${root}
              set prefix=${biosPrefix}
            EOS

            ${pkgs.grub2_efi}/bin/grub-mkimage \
              -p '${biosPrefix}' \
              -O ${pkgs.grub2.grubTarget} \
              -c $grub_tmp/grub.cfg \
              -o /boot/grub/core.img \
              ${modules}

            grub_tmp=$(mktemp -d -t grub.conf.XXXXXXXX)

            trap 'rm -rf -- "$grub_tmp"' EXIT

            cat <<EOS >"$grub_tmp/grub.cfg"
              cryptomount -u $(${pkgs.utillinux}/bin/blkid -o value -s UUID ${escapeShellArg config.boot.initrd.luks.devices.${cfg.disk.luksDisk}.device})
              set root=${root}
              set prefix=${efiPrefix}
            EOS

            mkdir -p ${escapeShellArg (builtins.dirOf stub)}

            ${pkgs.grub2_efi}/bin/grub-mkimage \
              -p '${efiPrefix}' \
              -O ${pkgs.grub2_efi.grubTarget} \
              -c $grub_tmp/grub.cfg \
              -o ${escapeShellArg stub} \
              ${modules}
          '';
        };
      };
    };
  };
}
