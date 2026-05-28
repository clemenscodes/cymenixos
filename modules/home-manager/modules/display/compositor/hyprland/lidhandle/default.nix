{pkgs, ...}:
pkgs.writeShellScriptBin "lidhandle" ''
  state=$1
  count_monitors=$(${pkgs.hyprland}/bin/hyprctl monitors | grep -c '^Monitor')
  if [ "$state" == "on" ]; then
    if [ "$count_monitors" = 1 ]; then
      ${pkgs.hyprlock}/bin/hyprlock
    else
      ${pkgs.hyprland}/bin/hyprctl eval 'hl.monitor({ output = "eDP-1", disabled = true })'
    fi
  else
    ${pkgs.hyprland}/bin/hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "1920x1200@60.01", position = "0x0", scale = 1 })'
  fi
''
