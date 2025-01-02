{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./bar {inherit inputs pkgs lib;})
    (import ./compositor {inherit inputs pkgs lib;})
    (import ./cursor {inherit inputs pkgs lib;})
    (import ./gtk {inherit inputs pkgs lib;})
    (import ./imageviewer {inherit inputs pkgs lib;})
    (import ./launcher {inherit inputs pkgs lib;})
    (import ./lockscreen {inherit inputs pkgs lib;})
    (import ./notifications {inherit inputs pkgs lib;})
    (import ./pdfviewer {inherit inputs pkgs lib;})
    (import ./qt {inherit inputs pkgs lib;})
    (import ./screenshots {inherit inputs pkgs lib;})
    (import ./vnc {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      display = {
        enable = lib.mkEnableOption "Enable a slick display configuration" // {default = false;};
      };
    };
  };
}
