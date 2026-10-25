# Scripted stage-1 initrd, manuell aus nixpkgs zurueckgeholt.
#
# nixpkgs hat die komplette scripted stage-1 (den bash basierten initrd init)
# entfernt und durch systemd stage-1 ersetzt. cymenixos setzt
# boot.initrd.systemd.enable auf mkForce false (modules/boot), will also
# genau den scripted Pfad. Zwei cymenixos Module haengen hart daran:
#
#  - modules/disk setzt boot.initrd.luks.yubikeySupport und
#    boot.initrd.luks.devices.<name>.yubikey, sobald security.yubikey.enable
#    an ist. Diese Optionen existieren nur in der scripted stage-1. (Das
#    bedeutet nicht, dass per YubiKey gebootet wird; die LUKS Root wird per
#    Passphrase entsperrt. Die Optionen sind nur Teil des disk Moduls.)
#  - modules/boot/impermanence macht den btrfs wipe-on-boot ueber
#    boot.initrd.postDeviceCommands. Auch dieser Hook existiert nur in der
#    scripted stage-1 und ist die kritische Abhaengigkeit dieses Systems.
#
# Als nixpkgs die scripted stage-1 entfernte (alle genannten Optionen und
# die *Commands Hooks wurden zu mkRemovedOptionModule Stubs), brach die
# Evaluation. Hier werden die upstream Module, die den Code geloescht bzw.
# in Stubs verwandelt haben, per disabledModules abgeschaltet und durch die
# unveraenderten Vorentfernungs-Versionen ersetzt. Quelle ist der nixpkgs
# Commit, mit dem das laufende System noch gebaut wurde
# (6774f7bc253789b113a4f39285dc0fa100abeacc, 26.11 vom 2026-09-22), also
# exakt der Code der aktuell bootet.
#
# Es ist bewusst der vollstaendige, in sich konsistente Satz der vom
# Entfernungs-Commit beruehrten Dateien, nicht nur luksroot.nix. Sobald die
# Option boot.initrd.systemd.enable durch das zurueckgeholte
# systemd/initrd.nix wieder existiert, greift das mkForce false und der
# scripted Pfad wird aktiv.
#
# Drei Referenzen zeigen aus dem nixpkgs Baum heraus und wurden auf
# modulesPath umgebogen (top-level.nix: ../build.nix und
# ../../../lib/from-env.nix; initrd-ssh.nix: der Testschluessel). build.nix
# ist zwischen alt und neu identisch, from-env.nix und der Testschluessel
# existieren im aktuellen nixpkgs weiter.
#
# Bei jedem vanix/nixpkgs Bump pruefen, ob die ersetzten Dateien upstream
# weiter so aussehen, sonst driftet dieser Satz gegen den Rest von nixpkgs.
{...}: {
  disabledModules = [
    "system/activation/top-level.nix"
    "system/boot/stage-1.nix"
    "system/boot/luksroot.nix"
    "system/boot/clevis.nix"
    "system/boot/clevis-luks-askpass.nix"
    "system/boot/initrd-network.nix"
    "system/boot/initrd-ssh.nix"
    "system/boot/initrd-openvpn.nix"
    "system/boot/stratisroot.nix"
    "system/boot/systemd/initrd.nix"
    "system/boot/systemd/initrd-secrets.nix"
  ];

  imports = [
    ./system/activation/top-level.nix
    ./system/boot/stage-1.nix
    ./system/boot/luksroot.nix
    ./system/boot/clevis.nix
    ./system/boot/clevis-luks-askpass.nix
    ./system/boot/initrd-network.nix
    ./system/boot/initrd-ssh.nix
    ./system/boot/initrd-openvpn.nix
    ./system/boot/stratisroot.nix
    ./system/boot/systemd/initrd.nix
    ./system/boot/systemd/initrd-secrets.nix
  ];
}
