{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./dolphin {inherit inputs pkgs lib;})
    (import ./lf {inherit inputs pkgs lib;})
    (import ./yazi {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      explorer = {
        enable = lib.mkEnableOption "Enable a file explorer" // {default = false;};
        defaultExplorer = lib.mkOption {
          type = lib.types.enum ["lf" "yazi"];
          default = "yazi";
        };
      };
    };
  };
}
