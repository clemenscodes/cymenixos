{
  inputs,
  pkgs,
  lib,
  ...
}: {
  imports = [
    (import ./pycharm {inherit inputs pkgs lib;})
    (import ./clion {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      editor = {
        jetbrains = {
          enable = lib.mkEnableOption "Enables JetBrains products" // {default = false;};
        };
      };
    };
  };
}
