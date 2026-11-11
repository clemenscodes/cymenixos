# Die Hooks der scripted stage-1 aus tasks/filesystems/btrfs.nix.
#
# Upstream legt btrfs-progs nur noch über boot.initrd.systemd.initrdBin in
# die initrd. Das wirkt allein in der systemd stage-1, im scripted initrd
# fehlt dadurch das btrfs Binary, und der Wipe von modules/boot/impermanence
# in postDeviceCommands bricht ab. Der Rest des upstream Moduls (Kernelmodule,
# fsPackages, autoScrub) gilt unverändert weiter, deshalb wird das Modul nicht
# ersetzt, sondern nur um diese Hooks ergänzt, wortgleich aus nixpkgs
# 6774f7bc253789b113a4f39285dc0fa100abeacc.
{
  config,
  lib,
  pkgs,
  ...
}: let
  inInitrd = config.boot.initrd.supportedFilesystems.btrfs or false;
in {
  config = lib.mkIf (inInitrd && !config.boot.initrd.systemd.enable) {
    boot.initrd.extraUtilsCommands = ''
      copy_bin_and_libs ${pkgs.btrfs-progs}/bin/btrfs
      ln -sv btrfs $out/bin/btrfsck
      ln -sv btrfsck $out/bin/fsck.btrfs
    '';

    boot.initrd.extraUtilsCommandsTest = ''
      $out/bin/btrfs --version
    '';

    boot.initrd.postDeviceCommands = ''
      btrfs device scan
    '';
  };
}
