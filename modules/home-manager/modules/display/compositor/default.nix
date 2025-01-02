{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./hyprland {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      display = {
        compositor = {
          enable = lib.mkEnableOption "Enable the best compositor" // {default = false;};
          defaultCompositor = lib.mkOption {
            type = lib.types.enum ["hyprland"];
            default = "hyprland";
          };
        };
      };
    };
  };
}
