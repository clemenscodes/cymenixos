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
  cfg = config.modules;
in {
  imports = [
    (import ./amd {inherit inputs pkgs lib;})
    (import ./nvidia {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      gpu = {
        enable = lib.mkEnableOption "Enable GPU support" // {default = false;};
      };
    };
  };
  config = {
    hardware = {
      graphics = {
        inherit (cfg.gpu) enable;
        enable32Bit = true;
      };
    };
  };
}
