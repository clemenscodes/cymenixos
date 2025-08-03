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
    environment = {
      systemPackages = [
        pkgs.clinfo
        pkgs.glxinfo
        pkgs.glmark2
        pkgs.libva
        pkgs.libva-utils
        pkgs.vdpauinfo
        pkgs.vulkan-tools
        pkgs.vulkan-loader
        pkgs.vulkan-validation-layers
        pkgs.vulkan-extension-layer
      ];
    };
    hardware = {
      graphics = {
        inherit (cfg.gpu) enable;
        enable32Bit = true;
        extraPackages = [
          pkgs.mesa.opencl
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
          pkgs.pkgsi686Linux.mesa.opencl
          pkgs.pkgsi686Linux.intel-media-driver
          pkgs.pkgsi686Linux.intel-vaapi-driver
        ];
      };
    };
    systemd = {
      tmpfiles = {
        rules = let
          rocmEnv = pkgs.symlinkJoin {
            name = "rocm-combined";
            paths = with pkgs.rocmPackages; [
              rocblas
              hipblas
              clr
            ];
          };
        in [
          "L+    /opt/rocm   -    -    -     -    ${rocmEnv}"
        ];
      };
    };
  };
}
