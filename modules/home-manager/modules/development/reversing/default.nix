{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./binaryninja {inherit inputs pkgs lib;})
    (import ./ghidra {inherit inputs pkgs lib;})
    (import ./ida {inherit inputs pkgs lib;})
    (import ./imhex {inherit inputs pkgs lib;})
    (import ./pince {inherit inputs pkgs lib;})
    (import ./pwndbg {inherit inputs pkgs lib;})
    (import ./radare2 {inherit inputs pkgs lib;})
    (import ./strace {inherit inputs pkgs lib;})
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
