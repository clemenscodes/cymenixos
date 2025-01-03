{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./base {inherit inputs pkgs lib;})
    (import ./catppuccin {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      themes = {
        enable = lib.mkEnableOption "Enable slick themes" // {default = false;};
        defaultTheme = lib.mkOption {
          type = lib.types.enum ["catppuccin" "base"];
          default = "catppuccin";
        };
      };
    };
  };
}
