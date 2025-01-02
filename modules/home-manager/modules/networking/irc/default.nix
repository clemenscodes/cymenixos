{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./pidgin {inherit inputs pkgs lib;})
    (import ./irssi {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      networking = {
        irc = {
          enable = lib.mkEnableOption "Enable irc" // {default = false;};
        };
      };
    };
  };
}
