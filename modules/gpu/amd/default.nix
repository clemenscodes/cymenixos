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
  cfg = config.modules.gpu;
  driver = "amdgpu";
in {
  imports = [
    (import ./corectrl {inherit inputs pkgs lib;})
    (import ./lact {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      gpu = {
        amd = {
          enable = lib.mkEnableOption "Enable AMD GPU support" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.amd.enable) {
    environment = {
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
    boot = {
      initrd = {
        kernelModules = [driver];
      };
      kernelModules = [driver];
    };
    services = {
      xserver = {
        enable = true;
        videoDrivers = [driver];
      };
    };
  };
}
