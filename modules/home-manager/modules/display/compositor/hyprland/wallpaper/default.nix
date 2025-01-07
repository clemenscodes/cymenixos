{pkgs, ...}:
pkgs.writeShellScriptBin "wallpaper" ''
  sleep 0.4
  ${pkgs.swww}/bin/swww-daemon -q && \
    while : ; do
       for file in $(ls $XDG_WALLPAPER_DIR/*); do
         swww img "$file"
         sleep 3600
       done
    done
''
