{pkgs, ...}:
pkgs.writeShellScriptBin "fullscreenshot" ''
  ${pkgs.grim}/bin/grim $XDG_SCREENSHOT_DIR/'''$(${pkgs.busybox}/bin/date +%s).png
''
