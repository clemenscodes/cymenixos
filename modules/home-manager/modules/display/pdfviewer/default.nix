{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./calibre {inherit inputs pkgs lib;})
    (import ./zathura {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      display = {
        pdfviewer = {
          enable = lib.mkEnableOption "Enable PDF Viewer" // {default = false;};
          defaultPdfViewer = lib.mkOption {
            type = lib.types.enum ["zathura"];
            default = "zathura";
          };
        };
      };
    };
  };
}
