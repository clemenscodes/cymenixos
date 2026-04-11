{pkgs, ...}:
pkgs.writeShellScriptBin "screenshot" ''
  file=$XDG_SCREENSHOT_DIR/$(${pkgs.busybox}/bin/date +%s).png
  ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | \
    ${pkgs.imagemagick}/bin/convert - -shave 1x1 PNG:- | \
    ${pkgs.coreutils}/bin/tee "$file" | \
    ${pkgs.wl-clipboard}/bin/wl-copy
''
