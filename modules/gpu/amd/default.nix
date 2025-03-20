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
    environment = {
      systemPackages = [
        pkgs.clinfo
        pkgs.vulkan-tools
        pkgs.vulkan-loader
        pkgs.vulkan-validation-layers
        pkgs.rocmPackages.clr
        pkgs.rocmPackages.clr.icd
        inputs.gpu-usage-waybar.packages.${system}.gpu-usage-waybar
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
          pkgs.rocmPackages.clr
          pkgs.rocmPackages.clr.icd
          pkgs.mesa
          pkgs.amdvlk
        ];
        extraPackages32 = [
          pkgs.driversi686Linux.mesa
          pkgs.driversi686Linux.amdvlk
        ];
      };
    };
  };
}
