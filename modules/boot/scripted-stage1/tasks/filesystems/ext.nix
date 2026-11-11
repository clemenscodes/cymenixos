# Die Hooks der scripted stage-1 aus tasks/filesystems/ext.nix.
#
# In der scripted stage-1 kamen e2fsck, tune2fs, e2fsprogs und die ext2/ext4
# Kernelmodule bedingungslos in die initrd, damit stage-1 jedes ext Dateisystem
# prüfen und mounten kann. Upstream koppelt alles an
# boot.initrd.supportedFilesystems.ext*, und das e2fsck in extraUtils fehlt
# ganz. Wortgleich aus nixpkgs 6774f7bc253789b113a4f39285dc0fa100abeacc.
{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf (!config.boot.initrd.systemd.enable) {
    system.fsPackages = [pkgs.e2fsprogs];

    boot.initrd.availableKernelModules = [
      "ext2"
      "ext4"
    ];

    boot.initrd.extraUtilsCommands = ''
      # Copy e2fsck and friends.
      copy_bin_and_libs ${pkgs.e2fsprogs}/sbin/e2fsck
      copy_bin_and_libs ${pkgs.e2fsprogs}/sbin/tune2fs
      ln -sv e2fsck $out/bin/fsck.ext2
      ln -sv e2fsck $out/bin/fsck.ext3
      ln -sv e2fsck $out/bin/fsck.ext4
    '';
  };
}
