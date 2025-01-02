{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./swayimg {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      display = {
        imageviewer = {
          enable = lib.mkEnableOption "Enable image viewer" // {default = false;};
          defaultImageViewer = lib.mkOption {
            type = lib.types.enum ["swayimg"];
            default = "swayimg";
          };
        };
      };
    };
  };
}
