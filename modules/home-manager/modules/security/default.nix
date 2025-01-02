{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./bitwarden {inherit inputs pkgs lib;})
    (import ./ssh {inherit inputs pkgs lib;})
    (import ./gpg {inherit inputs pkgs lib;})
    (import ./sops {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      security = {
        enable = lib.mkEnableOption "Enable tools for security" // {default = false;};
      };
    };
  };
}
