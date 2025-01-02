{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./multiplexers {inherit inputs pkgs lib;})
    (import ./nom {inherit inputs pkgs lib;})
    (import ./nvd {inherit inputs pkgs lib;})
    (import ./starship {inherit inputs pkgs lib;})
    (import ./zoxide {inherit inputs pkgs lib;})
    (import ./zsh {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      shell = {
        enable = lib.mkEnableOption "Enable home-manager shell modules" // {default = false;};
        defaultShell = lib.mkOption {
          type = lib.types.enum ["zsh" "bash"];
          default = "zsh";
        };
      };
    };
  };
}
