{ pkgs, ... }:
pkgs.writeShellScriptBin "random-wallpaper" ''
  until ${pkgs.awww}/bin/awww query &>/dev/null; do
    sleep 0.1
  done
  wallpaper="$(echo "$(for file in $(ls "$XDG_WALLPAPER_DIR"); do echo $file; done)" | shuf | head -n1)"
  ln -sf "$wallpaper" "$XDG_WALLPAPER_DIR/random"
  ${pkgs.awww}/bin/awww img "$XDG_WALLPAPER_DIR/random"
  echo "Setting wallpaper to $wallpaper"
''
