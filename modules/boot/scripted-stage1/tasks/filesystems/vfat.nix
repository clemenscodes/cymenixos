# Die Hooks der scripted stage-1 aus tasks/filesystems/vfat.nix.
#
# Upstream legt dosfstools nur noch über boot.initrd.systemd.initrdBin in die
# initrd, in der scripted stage-1 fehlt damit fsck.vfat. Wortgleich aus nixpkgs
# 6774f7bc253789b113a4f39285dc0fa100abeacc.
{
  config,
  lib,
  pkgs,
  ...
}: let
  inInitrd = config.boot.initrd.supportedFilesystems.vfat or false;
in {
  config = lib.mkIf ((config.boot.supportedFilesystems.vfat or false) && inInitrd && !config.boot.initrd.systemd.enable) {
    boot.initrd.extraUtilsCommands = ''
      copy_bin_and_libs ${pkgs.dosfstools}/sbin/dosfsck
      ln -sv dosfsck $out/bin/fsck.vfat
    '';
  };
}
