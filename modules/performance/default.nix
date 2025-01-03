{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./auto-cpufreq {inherit inputs pkgs lib;})
    (import ./power {inherit inputs pkgs lib;})
    (import ./thermald {inherit inputs pkgs lib;})
    (import ./tlp {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      performance = {
        enable = lib.mkEnableOption "Enable performance tweaks" // {default = false;};
      };
    };
  };
}
