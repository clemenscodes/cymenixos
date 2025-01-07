{pkgs, ...}: let
  wallpapers = pkgs.stdenv.mkDerivation {
    name = "wallpapers";
    src = pkgs.fetchFromGitHub {
      owner = "clemenscodes";
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
  pkgs.writeShellScriptBin "random-wallpaper" ''
    wallpaper="${wallpapers}/$(echo "$(for file in $(ls "${wallpapers}/"); do echo $file; done)" | shuf | head -n1)"
    echo "Setting random wallpaper $wallpaper to $XDG_WALLPAPER_DIR/random"
    ln -sf "$wallpaper" "$XDG_WALLPAPER_DIR/random"
    echo "Setting wallpaper to $wallpaper"
    ${pkgs.swww}/bin/swww img "$XDG_WALLPAPER_DIR/random"
  ''
