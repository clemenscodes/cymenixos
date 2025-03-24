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
  config = {
    hardware = {
      graphics = {
        inherit (cfg.gpu) enable;
        enable32Bit = true;
      };
    };
    chaotic = {
      mesa-git = {
        inherit (cfg.nyx) enable;
        extraPackages = [
          pkgs.mesa_git.opencl
          pkgs.intel-media-driver
          pkgs.rocmPackages.clr
          pkgs.rocmPackages.clr.icd
          pkgs.rocmPackages.rocm-runtime
          pkgs.libdrm
          pkgs.libva
          pkgs.libva-vdpau-driver
          pkgs.libvdpau-va-gl
          pkgs.intel-vaapi-driver
          pkgs.vkd3d
          pkgs.vkd3d-proton
        ];
        extraPackages32 = [
          pkgs.pkgsi686Linux.mesa32_git.opencl
          pkgs.pkgsi686Linux.intel-media-driver
          pkgs.pkgsi686Linux.intel-vaapi-driver
        ];
      };
    };
  };
}
