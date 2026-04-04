{pkgs, ...}: let
  random-wallpaper = import ../random-wallpaper {inherit pkgs;};
in
  pkgs.writeShellScriptBin "wallpaper" ''
    while true; do
      ${random-wallpaper}/bin/random-wallpaper
      sleep 3600
    done
  ''
