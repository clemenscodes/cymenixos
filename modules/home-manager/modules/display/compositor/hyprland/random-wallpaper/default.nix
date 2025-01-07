{pkgs, ...}:
pkgs.writeShellScriptBin "random-wallpaper" ''
  wallpaper="$(echo "$(for file in $(ls "$XDG_WALLPAPER_DIR"); do echo $file; done)" | grep /nix | shuf | head -n1)"
  echo "Setting random wallpaper $wallpaper to $XDG_WALLPAPER_DIR/random"
  ln -sf "$wallpaper" "$XDG_WALLPAPER_DIR/random"
  echo "Setting wallpaper to $wallpaper"
  ${pkgs.swww}/bin/swww img "$XDG_WALLPAPER_DIR/random"
''
