{pkgs, ...}:
pkgs.writeShellScriptBin "wallpaper" ''
  while : ; do
    wallpapers=$(echo "$(for file in $(ls $XDG_WALLPAPER_DIR); do echo $file; done)" | grep /nix | shuf)
    for file in "$wallpapers"; do
      echo "Setting random wallpaper to $XDG_WALLPAPER_DIR/random"
      cp $(echo $wallpapers | tail -n1) $XDG_WALLPAPER_DIR/random
      echo "Setting wallpaper to $file"
      ${pkgs.swww}/bin/swww img "$file"
      sleep 3600
    done
  done
''
