{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: let
  emoji = pkgs.writeShellScriptBin "emoji" ''
    rofi -modi emoji -show emoji
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
            "$mod SHIFT, D, exec, ${emoji}/bin/emoji"
          ];
        };
      };
    };
  };
}
