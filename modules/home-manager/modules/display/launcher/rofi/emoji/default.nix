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
        extraConfig = ''
          hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd("${emoji}/bin/emoji"))
        '';
      };
    };
  };
}
