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
        package = pkgs.nix-ld;
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
          pkgs.stdenv.cc.cc.lib
          pkgs.xorg.libXcomposite
          pkgs.xorg.libXtst
          pkgs.xorg.libXrandr
          pkgs.xorg.libXext
          pkgs.xorg.libX11
          pkgs.xorg.libXfixes
          pkgs.libGL
          pkgs.libva
          pkgs.fontconfig
          pkgs.freetype
          pkgs.xorg.libXt
          pkgs.xorg.libXmu
          pkgs.libogg
          pkgs.libvorbis
          pkgs.SDL
          pkgs.SDL2_image
          pkgs.glew110
          pkgs.libdrm
          pkgs.libidn
          pkgs.tbb
          pkgs.zlib
        ];
      };
    };
  };
}
