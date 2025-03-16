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
        pkgs.glxinfo
        pkgs.glmark2
        pkgs.libva-utils
        pkgs.vulkan-tools
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
      amdgpu = {
        amdvlk = {
          enable = true;
          support32Bit = {
            enable = true;
          };
          supportExperimental = {
            enable = true;
          };
          settings = {
            AllowVkPipelineCachingToDisk = 1;
            EnableVmAlwaysValid = 1;
            IFH = 0;
            IdleAfterSubmitGpuMask = 1;
            ShaderCacheMode = 1;
          };
        };
        initrd = {
          enable = true;
        };
        opencl = {
          enable = true;
        };
      };
      graphics = {
        enable = true;
        extraPackages = [
          pkgs.amdvlk
          pkgs.mesa
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
