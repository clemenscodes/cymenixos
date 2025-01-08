{
  inputs,
  pkgs,
  lib,
  ...
}: {osConfig, ...}: {
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
  config = lib.mkIf osConfig.modules.security.gnome-keyring.enable {
    services = {
      gnome-keyring = {
        enable = true;
        components = ["pkcs11" "secrets" "ssh"];
      };
    };
  };
}
