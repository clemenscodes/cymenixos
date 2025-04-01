{
  inputs,
  pkgs,
  lib,
}: {...}: {
  imports = [
    (import ./direnv {inherit inputs pkgs lib;})
    (import ./gh {inherit inputs pkgs lib;})
    (import ./git {inherit inputs pkgs lib;})
    (import ./pentesting {inherit inputs pkgs lib;})
    (import ./postman {inherit inputs pkgs lib;})
    (import ./reversing {inherit inputs pkgs lib;})
    (import ./tongo {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      development = {
        enable = lib.mkEnableOption "Enable development tools" // {default = false;};
      };
    };
  };
}
