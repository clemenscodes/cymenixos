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
    modules = {
      gpu = {
        vendor = "amd";
      };
    };
    hardware = {
      graphics = {
        package = pkgs.amdvlk;
        package32 = pkgs.driversi686Linux.amdvlk;
        extraPackages = [
          pkgs.mesa
          pkgs.libdrm
          pkgs.libva
          pkgs.libva-vdpau-driver
          pkgs.libvdpau-va-gl
          pkgs.intel-vaapi-driver
          pkgs.intel-media-driver
          pkgs.rocmPackages.clr
          pkgs.rocmPackages.clr.icd
        ];
        extraPackages32 = [
          pkgs.driversi686Linux.mesa
          pkgs.driversi686Linux.libva-vdpau-driver
          pkgs.driversi686Linux.libvdpau-va-gl
          pkgs.driversi686Linux.intel-vaapi-driver
          pkgs.driversi686Linux.intel-media-driver
        ];
      };
    };
    environment = {
      systemPackages = [
        pkgs.clinfo
        pkgs.glxinfo
        pkgs.glmark2
        pkgs.libva
        pkgs.libva-utils
        pkgs.vdpauinfo
        pkgs.vulkan-tools
        inputs.gpu-usage-waybar.packages.${system}.gpu-usage-waybar
      ];
      variables = {
        OCL_ICD_VENDORS = "${pkgs.rocmPackages.clr.icd}/etc/OpenCL/vendors/";
        VDPAU_DRIVER = "radeonsi";
        LIBVA_DRIVER_NAME = "iHD";
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
