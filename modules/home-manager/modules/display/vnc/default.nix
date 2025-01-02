{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./wayvnc {inherit inputs pkgs lib;})
    (import ./tigervnc {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      display = {
        vnc = {
          enable = lib.mkEnableOption "Enable VNC" // {default = false;};
          defaultVNC = lib.mkOption {
            type = lib.types.enum ["wayvnc" "tigervnc"];
            default = "wayvnc";
          };
        };
      };
    };
  };
}
