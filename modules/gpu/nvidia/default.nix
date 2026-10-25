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
      # CUDA splits and renames its components on every major bump (13.4 added
      # libnvvm, renamed cuda_cccl to cccl, added cuda_crt, ...), so an explicit
      # per-package allowlist breaks on each toolkit bump. This pkgs is built for
      # the nvidia/cuda stack only, so allow its unfree bits wholesale, matching
      # how the strata and vibevoice modules already handle their cuda pkgs.
      allowUnfree = true;
    };
  };
in {
  imports = [
    (import ./pyroveil {inherit lib;})
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
    boot = {
      blacklistedKernelModules = ["nouveau"];
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
        package = config.boot.kernelPackages.nvidiaPackages.stable;
        open = true;
        nvidiaSettings = true;
        nvidiaPersistenced = false;
      };
      graphics = {
        extraPackages = [pkgs.nvidia-vaapi-driver];
        extraPackages32 = [pkgs.pkgsi686Linux.nvidia-vaapi-driver];
      };
    };
  };
}
