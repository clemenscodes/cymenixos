{
  inputs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.io;
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["wootility"];
    };
  };
  wootilityVersion = "5.2.5";
  wootilitySrc = pkgs.fetchurl {
    url = "https://wootility-updates.ams3.cdn.digitaloceanspaces.com/wootility-linux/Wootility-${wootilityVersion}.AppImage";
    hash = "sha256-bDhwlI+zi13xdMXqT5ztzR7RNOLgTBxNtjGkEFezZsw=";
  };
  wootilityContents = pkgs.appimageTools.extract {
    pname = "wootility";
    version = wootilityVersion;
    src = wootilitySrc;
  };
  wootility = pkgs.appimageTools.wrapType2 {
    pname = "wootility";
    version = wootilityVersion;
    src = wootilitySrc;
    nativeBuildInputs = [pkgs.makeWrapper];
    extraInstallCommands = ''
      wrapProgram $out/bin/wootility \
        --add-flags "--disable-gpu-sandbox" \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"

      install -Dm444 ${wootilityContents}/wootility.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/wootility.desktop \
        --replace-fail 'Exec=AppRun --no-sandbox' 'Exec=wootility'

      for size in 16x16 32x32 48x48 64x64 128x128 256x256 512x512 1024x1024; do
        if [ -f ${wootilityContents}/usr/share/icons/hicolor/$size/apps/wootility.png ]; then
          install -Dm444 ${wootilityContents}/usr/share/icons/hicolor/$size/apps/wootility.png \
            $out/share/icons/hicolor/$size/apps/wootility.png
        fi
      done
    '';
    profile = ''
      export LC_ALL=C.UTF-8
    '';
    extraPkgs = epkgs:
      with epkgs; [
        libxkbfile
      ];
    meta = pkgs.wootility.meta;
  };
in {
  options = {
    modules = {
      io = {
        wooting = {
          enable =
            lib.mkEnableOption "Enable support for wooting"
            // {
              default = false;
            };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.wooting.enable) {
    environment.systemPackages = [wootility];
    services.udev.packages = [pkgs.wooting-udev-rules];
  };
}
