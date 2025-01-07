{pkgs, ...}: let
  wallpapers = pkgs.stdenv.mkDerivation {
    name = "wallpapers";
    src = pkgs.fetchFromGitHub {
      owner = "orangci";
      repo = "walls";
      rev = "886dd0786cea003f9e94a1054137e7cbd8fd7428";
      hash = "sha256-GjP7ASUjfL9kqIx+/dhGkiBm1QmjwWn80bqhi3Vp6vM=";
    };
    installPhase = ''
      mkdir -p $out
      cp -r $src/* $out
      rm $out/README.md
    '';
  };
in
  pkgs.writeShellScriptBin "wallpaper" ''
    while : ; do
      wallpapers=($(echo "$(for file in $(ls "${wallpapers}/"); do echo $file; done)" | shuf))
      echo "Currently there are ''${#wallpapers[@]} wallpapers installed"
      for wallpaper in $wallpapers; do
        echo "Setting wallpaper to $wallpaper"
        ${pkgs.swww}/bin/swww img "$wallpaper"
        echo "Setting random wallpaper $wallpaper to $XDG_WALLPAPER_DIR/random"
        rm "$XDG_WALLPAPER_DIR/random"
        cp "$wallpaper" "$XDG_WALLPAPER_DIR/random"
        sleep 3600
      done
    done
  ''
