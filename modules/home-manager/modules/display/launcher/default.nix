{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./anyrun {inherit inputs pkgs lib;})
    (import ./rofi {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      display = {
        launcher = {
          enable = lib.mkEnableOption "Enable launchers" // {default = false;};
          defaultLauncher = lib.mkOption {
            type = lib.types.enum ["rofi" "anyrun"];
            default = "rofi";
          };
        };
      };
    };
  };
}
