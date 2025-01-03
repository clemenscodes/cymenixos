{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
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
    environment = {
      systemPackages = [
        pkgs.clinfo
        pkgs.glxinfo
        pkgs.glmark2
        pkgs.libva-utils
        pkgs.vulkan-tools
        (import ./gpu-usage-waybar {inherit inputs pkgs lib;})
      ];
      variables = {
        OCL_ICD_VENDORS = "${pkgs.rocmPackages.clr.icd}/etc/OpenCL/vendors/";
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
        rules = [
          "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
        ];
      };
    };
    hardware = {
      graphics = {
        enable = true;
        extraPackages = [
          pkgs.amdvlk
          pkgs.mesa
          pkgs.mesa.drivers
          pkgs.rocmPackages.clr
          pkgs.rocmPackages.clr.icd
          pkgs.rocmPackages.rocm-runtime
        ];
        extraPackages32 = [
          pkgs.driversi686Linux.amdvlk
          pkgs.driversi686Linux.mesa
        ];
      };
    };
  };
}
