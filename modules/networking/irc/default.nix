{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./weechat {inherit inputs pkgs lib;})
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
