{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./dlplaylist {inherit inputs pkgs lib;})
    (import ./ncmpcpp {inherit inputs pkgs lib;})
    (import ./spotdl {inherit inputs pkgs lib;})
    (import ./spotify {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      media = {
        music = {
          enable = lib.mkEnableOption "Enable music" // {default = false;};
        };
      };
    };
  };
}
