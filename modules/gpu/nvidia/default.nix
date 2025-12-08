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
      cudaSupport = true;
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
    boot = {
      blacklistedKernelModules = ["nouveau"];
      kernelModules = [
        "nvidia"
        "nvidia_modeset"
        "nvidia_uvm"
        "nvidia_drm"
      ];
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
          enable = false;
          finegrained = false;
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
