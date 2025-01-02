{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./calcurse {inherit inputs pkgs lib;})
    (import ./email {inherit inputs pkgs lib;})
    (import ./libreoffice {inherit inputs pkgs lib;})
    (import ./zotero {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      organization = {
        enable = lib.mkEnableOption "Enable tools for organization" // {default = false;};
      };
    };
  };
}
