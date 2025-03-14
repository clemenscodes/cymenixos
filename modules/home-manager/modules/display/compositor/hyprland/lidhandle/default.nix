{pkgs, ...}:
pkgs.writeShellScriptBin "lidhandle" ''
  state=$1
  count_monitors=$(${pkgs.hyprland}/bin/hyprctl monitors | grep -c '^Monitor')
  if [ "$state" == "on" ]; then
    if [ "$count_monitors" = 1 ]; then
      ${pkgs.hyprlock}/bin/hyprlock
    else
      ${pkgs.hyprland}/bin/hyprctl keyword monitor "eDP-1, disable"
    fi
  else
    ${pkgs.hyprland}/bin/hyprctl keyword monitor "eDP-1,1920x1080,0x0,1"
  fi
''
