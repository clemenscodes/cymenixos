{
  pkgs,
  config,
  ...
}:
pkgs.writeShellScriptBin "wallpaper" ''
  while : ; do
    wallpapers=($(echo "$(for file in $(ls ${config.xdg.userDirs.extraConfig.XDG_WALLPAPER_DIR}); do echo $file; done)" | grep /nix))
    echo "Currently there are ''${#wallpapers[@]} wallpapers installed"
    for wallpaper in $(shuf -e "''${wallpapers[@]}"); do
      echo "Setting wallpaper to $wallpaper"
      ${pkgs.swww}/bin/swww img "$wallpaper"
      echo "Setting random wallpaper $wallpaper to $XDG_WALLPAPER_DIR/random"
      cp "$wallpaper" "$XDG_WALLPAPER_DIR/random"
      sleep 3600
    done
  done
''
