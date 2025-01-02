{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [(import ./gh-dash {inherit inputs pkgs lib;})];
  options = {
    modules = {
      development = {
        gh = {
          plugins = {
            enable = lib.mkEnableOption "Enable GitHub CLI plugins" // {default = false;};
          };
        };
      };
    };
  };
}
