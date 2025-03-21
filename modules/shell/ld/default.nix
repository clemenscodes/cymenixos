{
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.shell;
in {
  options = {
    modules = {
      shell = {
        ld = {
          enable = lib.mkEnableOption "Enable nix-ld to fix many binary errors" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.ld.enable) {
    programs = {
      nix-ld = {
        enable = cfg.ld.enable;
        package = pkgs.nix-ld-rs;
        libraries = [
          pkgs.webkitgtk_4_1
          pkgs.gtk3
          pkgs.cairo
          pkgs.gdk-pixbuf
          pkgs.glib.dev
          pkgs.dbus
          pkgs.openssl_3
          pkgs.stdenv.cc.cc
          pkgs.systemd
          pkgs.pkg-config

          # common requirement for several games
          stdenv.cc.cc.lib

          # from https://github.com/NixOS/nixpkgs/blob/nixos-23.05/pkgs/games/steam/fhsenv.nix#L72-L79
          xorg.libXcomposite
          xorg.libXtst
          xorg.libXrandr
          xorg.libXext
          xorg.libX11
          xorg.libXfixes
          libGL
          libva

          # from https://github.com/NixOS/nixpkgs/blob/nixos-23.05/pkgs/games/steam/fhsenv.nix#L124-L136
          fontconfig
          freetype
          xorg.libXt
          xorg.libXmu
          libogg
          libvorbis
          SDL
          SDL2_image
          glew110
          libdrm
          libidn
          tbb
          zlib
        ];
      };
    };
  };
}
