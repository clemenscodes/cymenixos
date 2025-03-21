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
        pkgs.vulkanPackages_latest.gfxreconstruct
        pkgs.vulkanPackages_latest.glslang
        pkgs.vulkanPackages_latest.spirv-cross
        pkgs.vulkanPackages_latest.spirv-headers
        pkgs.vulkanPackages_latest.spirv-tools
        pkgs.vulkanPackages_latest.vulkan-extension-layer
        pkgs.vulkanPackages_latest.vulkan-headers
        pkgs.vulkanPackages_latest.vulkan-loader
        pkgs.vulkanPackages_latest.vulkan-tools
        pkgs.vulkanPackages_latest.vulkan-tools-lunarg
        pkgs.vulkanPackages_latest.vulkan-utility-libraries
        pkgs.vulkanPackages_latest.vulkan-validation-layers
        pkgs.vulkanPackages_latest.vulkan-volk
        pkgs.latencyflex-vulkan
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
          pkgs.vaapiIntel
          pkgs.rocmPackages.clr
          pkgs.rocmPackages.clr.icd
          pkgs.rocmPackages.rocm-runtime
        ];
        extraPackages32 = [
          pkgs.pkgsi686Linux.mesa_git.opencl
          pkgs.pkgsi686Linux.intel-media-driver
          pkgs.pkgsi686Linux.vaapiIntel
        ];
      };
    };
  };
}
