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
    environment = {
      systemPackages = [
        pkgs.libdrm_git
        pkgs.libdrm32_git
      ];
    };
    hardware = {
      graphics = lib.mkIf (!cfg.nyx.enable) {
        inherit (cfg.gpu) enable;
      };
    };
    chaotic = {
      mesa-git = {
        inherit (cfg.nyx) enable;
        extraPackages = [
          pkgs.mesa_git.opencl
          pkgs.intel-media-driver
          pkgs.intel-ocl
          pkgs.vaapiIntel
        ];
        extraPackages32 = [
          pkgs.pkgsi686Linux.mesa_git.opencl
          pkgs.pkgsi686Linux.intel-media-driver
          pkgs.pkgsi686Linux.intel-ocl
          pkgs.pkgsi686Linux.vaapiIntel
        ];
      };
    };
  };
}
