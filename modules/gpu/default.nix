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
        vendor = lib.mkOption {
          type = lib.types.enum ["amd" "nvidia"];
          default = "amd";
        };
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
        inputs.gpu-usage-waybar.packages.${system}.gpu-usage-waybar
      ];
      variables = {
        OCL_ICD_VENDORS = "${pkgs.rocmPackages.clr.icd}/etc/OpenCL/vendors/";
        __EGL_VENDOR_LIBRARY_DIRS = "/run/opengl-driver/share/glvnd/egl_vendor.d:/run/opengl-driver-32/share/glvnd/egl_vendor.d";
        LIBVA_DRIVERS_PATH = "/run/opengl-driver/lib/dri:/run/opengl-driver-32/lib/dri";
        VDPAU_DRIVER_PATH = "/run/opengl-driver/lib/vdpau:/run/opengl-driver-32/lib/vdpau";
        VK_DRIVER_FILES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json:/run/opengl-driver-32/share/vulkan/icd.d/radeon_icd.i686.json";
        VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json:/run/opengl-driver-32/share/vulkan/icd.d/radeon_icd.i686.json";
        VDPAU_DRIVER = "radeonsi";
        LIBVA_DRIVER_NAME = "radeonsi";
      };
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
