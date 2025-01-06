{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
  grub = pkgs.grub2_efi;
  modules = "part_gpt luks2 mdraid1x cryptodisk gcry_rijndael gcry_sha256 gcry_sha512 argon2 btrfs zfs true";
  stub = "${config.boot.loader.efi.efiSysMountPoint}/EFI/BOOT/BOOTX64.EFI";
  inherit (lib) escapeShellArg;
in {
  config = lib.mkIf (cfg.enable && cfg.boot.enable && !cfg.users.isIso) {
    boot = {
      loader = lib.mkIf (!cfg.boot.secureboot.enable) {
        grub = {
          enableCryptodisk = true;
          extraGrubInstallArgs = ["--efi-directory=/boot" "--modules=${modules}"];
          extraInstallCommands = ''
            grub_tmp=$(mktemp -d -t grub.conf.XXXXXXXX)
            trap 'rm -rf -- "$grub_tmp"' EXIT
            cat <<EOS >"$grub_tmp/grub.cfg"
              cryptomount -u $(${pkgs.utillinux}/bin/blkid -o value -s UUID ${escapeShellArg config.boot.initrd.luks.devices.${cfg.disk.luksDisk}.device})
              set root=(crypto0)
              set prefix=(crypto0)/boot/grub
            EOS
            mkdir -p ${escapeShellArg (builtins.dirOf stub)}
            ${grub}/bin/grub-mkimage \
              -p '(crypto0)/boot/grub' \
              -O ${grub.grubTarget} \
              -c $grub_tmp/grub.cfg \
              -o ${escapeShellArg stub} \
              ${modules}
          '';
        };
      };
    };
  };
}
