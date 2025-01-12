{pkgs, ...}: {
  arrow = import ./arrow.nix {inherit pkgs;};
  exifaufdio = import ./exifaudio.nix {inherit pkgs;};
  eza-preview = import ./eza-preview.nix {inherit pkgs;};
  full-border = import ./full-border.nix {inherit pkgs;};
  git = import ./git.nix {inherit pkgs;};
  glow = import ./glow.nix {inherit pkgs;};
  hexyl = import ./hexyl.nix {inherit pkgs;};
  miller = import ./miller.nix {inherit pkgs;};
  smart-enter = import ./smart-enter.nix {inherit pkgs;};
  smart-paste = import ./smart-paste.nix {inherit pkgs;};
  smart-switch = import ./smart-switch.nix {inherit pkgs;};
  smart-tab = import ./smart-tab.nix {inherit pkgs;};
  starship = import ./starship.nix {inherit pkgs;};
  wl-clipboard = import ./wl-clipboard.nix {inherit pkgs;};
}
