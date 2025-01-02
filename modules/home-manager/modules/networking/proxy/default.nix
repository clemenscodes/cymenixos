{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./charles {inherit inputs pkgs lib;})
    (import ./mitmproxy {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      networking = {
        proxy = {
          enable = lib.mkEnableOption "Enable proxy tools" // {default = false;};
        };
      };
    };
  };
}
