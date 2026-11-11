# Die Hooks der scripted stage-1 aus tasks/lvm.nix.
#
# LVM selbst bringt die vendorte stage-1.nix mit. Upstream fehlen aber die
# Werkzeuge für thin provisioning und VDO in extraUtils sowie die lvm.conf, die
# stage-1 für thin und dmeventd schreibt. Wortgleich aus nixpkgs
# 6774f7bc253789b113a4f39285dc0fa100abeacc.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.lvm;
  scripted = !config.boot.initrd.systemd.enable;
in {
  config = lib.mkMerge [
    (lib.mkIf (scripted && cfg.boot.thin.enable) {
      boot.initrd.extraUtilsCommands = ''
        for BIN in ${pkgs.thin-provisioning-tools}/bin/*; do
          copy_bin_and_libs $BIN
        done
      '';

      boot.initrd.extraUtilsCommandsTest = ''
        ls ${pkgs.thin-provisioning-tools}/bin/ | grep -v pdata_tools | while read BIN; do
          $out/bin/$(basename $BIN) --help > /dev/null
        done
      '';
    })
    (lib.mkIf (scripted && cfg.boot.vdo.enable) {
      boot.initrd.extraUtilsCommands = ''
        ls ${pkgs.vdo}/bin/ | while read BIN; do
          copy_bin_and_libs ${pkgs.vdo}/bin/$BIN
        done
        substituteInPlace $out/bin/vdorecover --replace "${pkgs.bash}/bin/bash" "/bin/sh"
        substituteInPlace $out/bin/adaptlvm --replace "${pkgs.bash}/bin/bash" "/bin/sh"
      '';

      boot.initrd.extraUtilsCommandsTest = ''
        exclude='adaptlvm|vdorecover|vdocalculatesize'
        ls ${pkgs.vdo}/bin/ | grep -vE "($exclude)" | while read BIN; do
          $out/bin/$(basename $BIN) --help > /dev/null
        done
      '';
    })
    (lib.mkIf (scripted && (cfg.dmeventd.enable || cfg.boot.thin.enable)) {
      boot.initrd.preLVMCommands = ''
        mkdir -p /etc/lvm
        cat << EOF >> /etc/lvm/lvm.conf
        ${lib.optionalString cfg.boot.thin.enable (
          lib.concatMapStringsSep "\n" (bin: "global/${bin}_executable = $(command -v ${bin})") [
            "thin_check"
            "thin_dump"
            "thin_repair"
            "cache_check"
            "cache_dump"
            "cache_repair"
          ]
        )}
        ${lib.optionalString cfg.dmeventd.enable ''
          dmeventd/executable = "$(command -v false)"
          activation/monitoring = 0
        ''}
        EOF
      '';
    })
  ];
}
