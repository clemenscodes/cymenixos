{pkgs, ...}:
pkgs.writeShellScriptBin "wallpaper" ''
  while : ; do
    wallpapers=$(echo "$(for file in $(ls $XDG_WALLPAPER_DIR); do echo $file; done)" | grep /nix | shuf)
    for file in "$wallpapers"; do
      random_wallpaper=$(echo $wallpapers | tail -n1)
      echo "Setting random wallpaper $random_wallpaper to $XDG_WALLPAPER_DIR/random"
      cp $random_wallpaper $XDG_WALLPAPER_DIR/random
      echo "Setting wallpaper to $file"
      ${pkgs.swww}/bin/swww img "$file"
      sleep 3600
    done
  done
''
