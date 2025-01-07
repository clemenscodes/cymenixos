{pkgs, ...}:
pkgs.writeShellScriptBin "wallpaper" ''
  while : ; do
    for file in $(echo "$(for file in $(ls $XDG_WALLPAPER_DIR); do echo $file; done)" | grep /nix | shuf); do
       echo "Setting wallpaper to $file"
       ${pkgs.swww}/bin/swww img "$file"
       sleep 3600
    done
  done
''
