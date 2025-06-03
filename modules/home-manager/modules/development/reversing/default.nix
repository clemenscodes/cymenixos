{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./ghidra {inherit inputs pkgs lib;})
    (import ./ida {inherit inputs pkgs lib;})
    (import ./imhex {inherit inputs pkgs lib;})
    (import ./pince {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      development = {
        reversing = {
          enable = lib.mkEnableOption "Enable reversing support" // {default = false;};
        };
      };
    };
  };
}
