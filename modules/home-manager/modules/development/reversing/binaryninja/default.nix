{
  inputs,
  pkgs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.development.reversing;
in {
  options = {
    modules = {
      development = {
        reversing = {
          binaryninja = {
            enable = lib.mkEnableOption "Enable binary ninja" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.binaryninja.enable) {
    home = {
      packages = [inputs.binaryninja.packages.${system}.binary-ninja-free-wayland];
    };
  };
}
