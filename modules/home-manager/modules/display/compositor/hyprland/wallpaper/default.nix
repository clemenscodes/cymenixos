{pkgs, ...}:
pkgs.writeShellScriptBin "wallpaper" ''
  sleep 0.4
  ${pkgs.swww}/bin/swww-daemon
  echo "Wallpaper daemon started..."
  while : ; do
    for file in $(echo "$(for file in $(ls $XDG_WALLPAPER_DIR); do echo $file; done)" | grep /nix); do
       echo "Setting wallpaper to $file"
       ${pkgs.swww}/bin/swww img "$file"
       sleep 3600
    done
  done
''
