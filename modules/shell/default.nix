{
  inputs,
  pkgs,
  lib,
  cymenixos,
  ...
}: {...}: {
  imports = [
    (import ./console {inherit inputs pkgs lib;})
    (import ./environment {inherit inputs pkgs lib cymenixos;})
    (import ./ld {inherit inputs pkgs lib;})
    (import ./zsh {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      shell = {
        enable = lib.mkEnableOption "Enable shell configuration" // {default = false;};
        defaultShell = lib.mkOption {
          type = lib.types.enum [pkgs.zsh];
          default = pkgs.zsh;
        };
      };
    };
  };
}
