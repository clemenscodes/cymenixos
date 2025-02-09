{pkgs, ...}: let
  plugins = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "07258518f3bffe28d87977bc3e8a88e4b825291b";
    hash = "sha256-axoMrOl0pdlyRgckFi4DiS+yBKAIHDhVeZQJINh8+wk=";
  };
in {
  arrow = import ./arrow.nix {inherit pkgs plugins;};
  exifaufdio = import ./exifaudio.nix {inherit pkgs plugins;};
  eza-preview = import ./eza-preview.nix {inherit pkgs plugins;};
  full-border = import ./full-border.nix {inherit pkgs plugins;};
  git = import ./git.nix {inherit pkgs plugins;};
  glow = import ./glow.nix {inherit pkgs plugins;};
  hexyl = import ./hexyl.nix {inherit pkgs plugins;};
  miller = import ./miller.nix {inherit pkgs plugins;};
  smart-enter = import ./smart-enter.nix {inherit pkgs plugins;};
  smart-paste = import ./smart-paste.nix {inherit pkgs plugins;};
  smart-switch = import ./smart-switch.nix {inherit pkgs plugins;};
  smart-tab = import ./smart-tab.nix {inherit pkgs plugins;};
  starship = import ./starship.nix {inherit pkgs plugins;};
  wl-clipboard = import ./wl-clipboard.nix {inherit pkgs plugins;};
}
