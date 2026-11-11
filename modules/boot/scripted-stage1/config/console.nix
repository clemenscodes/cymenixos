# Die Hooks der scripted stage-1 aus config/console.nix.
#
# Upstream richtet die Konsole in der initrd nur noch über
# systemd-vconsole-setup ein, das es in der scripted stage-1 nicht gibt. Ohne
# diese Hooks gilt dort das Kernel Keymap (US), und zwar genau beim Eintippen
# der LUKS Passphrase. Wortgleich aus nixpkgs
# 6774f7bc253789b113a4f39285dc0fa100abeacc, samt der Hilfsdefinitionen, die
# das upstream Modul nur intern hält.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.console;

  isUnicode = config.i18n.defaultCharset == "UTF-8" || cfg.useXkbConfig;

  optimizedKeymap =
    pkgs.runCommand "keymap"
    {
      nativeBuildInputs = [pkgs.buildPackages.kbd];
      LOADKEYS_KEYMAP_PATH = "${consoleEnv pkgs.kbd}/share/keymaps/**";
      preferLocalBuild = true;
    }
    ''
      loadkeys -b ${lib.optionalString isUnicode "-u"} "${cfg.keyMap}" > $out
    '';

  consoleEnv = kbd:
    pkgs.buildEnv {
      name = "console-env";
      paths = [kbd] ++ cfg.packages;
      pathsToLink = [
        "/share/consolefonts"
        "/share/consoletrans"
        "/share/keymaps"
        "/share/unimaps"
      ];
    };
in {
  config = lib.mkIf (cfg.enable && !config.boot.initrd.systemd.enable) (lib.mkMerge [
    {
      boot.initrd.preLVMCommands = lib.mkBefore ''
        kbd_mode ${
          if isUnicode
          then "-u"
          else "-a"
        } -C /dev/console
        printf "\033%%${
          if isUnicode
          then "G"
          else "@"
        }" >> /dev/console
        loadkmap < ${optimizedKeymap}

        ${lib.optionalString (cfg.earlySetup && cfg.font != null) ''
          setfont -C /dev/console $extraUtils/share/consolefonts/font.psf
        ''}
      '';
    }

    (lib.mkIf (cfg.earlySetup && cfg.font != null) {
      boot.initrd.extraUtilsCommands = ''
        mkdir -p $out/share/consolefonts
        ${
          if lib.substring 0 1 cfg.font == "/"
          then ''
            font="${cfg.font}"
          ''
          else ''
            font="$(echo ${consoleEnv pkgs.kbd}/share/consolefonts/${cfg.font}.*)"
          ''
        }
        if [[ $font == *.gz ]]; then
          gzip -cd $font > $out/share/consolefonts/font.psf
        else
          cp -L $font $out/share/consolefonts/font.psf
        fi
      '';
    })
  ]);
}
