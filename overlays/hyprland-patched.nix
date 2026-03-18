# Replace upstream hyprland and xdg-desktop-portal-hyprland with patched forks
# that implement the wlr-screencopy v4 color_info event for HDR screencopy.
{
  inputs,
  system,
}:
final: prev: {
  hyprland = inputs.hyprland.packages.${system}.hyprland;
  xdg-desktop-portal-hyprland = inputs.xdg-desktop-portal-hyprland.packages.${system}.xdg-desktop-portal-hyprland;
}
