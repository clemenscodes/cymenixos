{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./newsboat {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      media = {
        rss = {
          enable = lib.mkEnableOption "Enable rss" // {default = false;};
        };
      };
    };
  };
}
