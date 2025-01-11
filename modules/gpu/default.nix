{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
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
        vendor = lib.mkOption {
          type = lib.types.enum ["amd" "nvidia"];
          default = "amd";
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.gpu.enable) {
    hardware = {
      graphics = {
        inherit (cfg.gpu) enable;
      };
    };
  };
}
