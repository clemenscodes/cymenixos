{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./quickshell {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      display = {
        bar = {
          enable = lib.mkEnableOption "Enable a cool bar" // {default = false;};
          defaultBar = lib.mkOption {
            type = lib.types.enum ["quickshell"];
            default = "quickshell";
          };
        };
      };
    };
  };
}
