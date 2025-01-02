{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./pcsx2 {inherit inputs pkgs lib;})
    (import ./rpcs3 {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      gaming = {
        emulation = {
          enable = lib.mkEnableOption "Enable emulation" // {default = false;};
        };
      };
    };
  };
}
