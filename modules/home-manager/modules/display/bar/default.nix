{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./waybar {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      display = {
        bar = {
          enable = lib.mkEnableOption "Enable a cool bar" // {default = false;};
          defaultBar = lib.mkOption {
            type = lib.types.enum ["waybar"];
            default = "waybar";
          };
        };
      };
    };
  };
}
