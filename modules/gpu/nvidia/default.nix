{
  inputs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.gpu;
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec "$@"
  '';
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          "nvidia-x11"
          "nvidia-settings"
          "nvidia-persistenced"
          "cuda-merged"
          "cuda_cuobjdump"
          "cuda_gdb"
          "cuda_nvcc"
          "cuda_nvdisasm"
          "cuda_nvprune"
          "cuda_cccl"
          "cuda_cudart"
          "cuda_cupti"
          "cuda_cuxxfilt"
          "cuda_nvml_dev"
          "cuda_nvrtc"
          "cuda_nvtx"
          "cuda_profiler_api"
          "cuda_sanitizer_api"
          "libcublas"
          "libcufft"
          "libcurand"
          "libcusolver"
          "libnvjitlink"
          "libcusparse"
          "libnpp"
          "cudnn"
        ];
    };
  };
in {
  imports = [
    (import ./scripts {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      gpu = {
        nvidia = {
          enable = lib.mkEnableOption "Enables NVIDIA GPU support" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.nvidia.enable) {
    modules = {
      gpu = {
        vendor = "nvidia";
      };
    };
    environment = {
      systemPackages = [
        nvidia-offload
        pkgs.cudaPackages.cudatoolkit
        pkgs.cudaPackages.cudnn
        pkgs.nvtopPackages.amd
        pkgs.nvtopPackages.nvidia
      ];
    };
    boot = {
      kernelModules = ["nvidia_uvm" "nvidia"];
      kernelParams = ["nvidia.NVreg_PreserveVideoMemoryAllocations=1"];
    };
    services = {
      xserver = {
        videoDrivers = ["nvidia"];
      };
    };
    hardware = {
      nvidia = {
        modesetting = {
          enable = true;
        };
        powerManagement = {
          # On wayland, suspend does not turn the screen back on when using the open source driver
          # Use proprietary driver if you want to use the suspend feature
          # as long as this issue is not fixed
          # @see https://github.com/NVIDIA/open-gpu-kernel-modules/issues/360
          enable = true;
          finegrained = true;
        };
        open = true;
        nvidiaSettings = true;
        nvidiaPersistenced = false;
        package = config.boot.kernelPackages.nvidiaPackages.beta;
      };
      graphics = {
        extraPackages = [pkgs.nvidia-vaapi-driver];
        extraPackages32 = [pkgs.pkgsi686Linux.nvidia-vaapi-driver];
      };
    };
  };
}
