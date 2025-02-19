{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./audio {inherit inputs pkgs lib;})
    (import ./communication {inherit inputs pkgs lib;})
    (import ./editing {inherit inputs pkgs lib;})
    (import ./games {inherit inputs pkgs lib;})
    (import ./music {inherit inputs pkgs lib;})
    (import ./rss {inherit inputs pkgs lib;})
    (import ./video {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      media = {
        enable = lib.mkEnableOption "Enable media" // {default = false;};
      };
    };
  };
}
