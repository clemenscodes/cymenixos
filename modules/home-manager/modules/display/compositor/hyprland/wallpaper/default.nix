{pkgs, ...}:
pkgs.writeShellScriptBin "wallpaper" ''
  while : ; do
    wallpapers=$(echo "$(for file in $(ls $XDG_WALLPAPER_DIR); do echo $file; done)" | grep /nix | shuf)
    echo "Currently there are $(echo "$wallpapers" | wc -l) installed"
    for wallpaper in "$wallpapers"; do
      echo "Setting wallpaper to $wallpaper"
      ${pkgs.swww}/bin/swww img "$wallpaper"
      echo "Setting random wallpaper $wallpaper to $XDG_WALLPAPER_DIR/random"
      cp "$wallpaper" "$XDG_WALLPAPER_DIR/random"
      sleep 3600
    done
  done
''
