{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: let
  emoji = pkgs.writeShellScriptBin "emoji" ''
    ${pkgs.rofi}/bin/rofi -modi emoji -show emoji -emoji-format '{emoji}'
  '';
in {
  home = {
    packages = [emoji];
  };
  wayland = {
    windowManager = {
      hyprland = {
        settings = {
          bind = [
            "$mod SHIFT, D, ${emoji}"
          ];
        };
      };
    };
  };
}
