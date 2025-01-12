{pkgs, ...}: {
  full-border = import ./full-border.nix.nix {inherit pkgs;};
  git = import ./git.nix {inherit pkgs;};
  smart-enter = import ./smart-enter.nix {inherit pkgs;};
  smart-paste = import ./smart-paste.nix {inherit pkgs;};
  smart-switch = import ./smart-switch.nix {inherit pkgs;};
  smart-tab = import ./smart-tab.nix {inherit pkgs;};
}
