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
  wayland = {
    windowManager = {
      hyprland = {
        bind = [
          "$mod SHIFT, D, ${emoji}/bin/emoji"
        ];
      };
    };
  };
}
