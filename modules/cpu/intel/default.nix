{
  pkgs,
  lib,
  ...
}: {config, ...}: {
  options = {
    modules = {
      cpu = {
        intel = {
          enable = lib.mkEnableOption "Enable Intel CPU settings" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (config.modules.cpu.enable && config.modules.cpu.intel.enable) {
    hardware = {
      cpu = {
        intel = {
          updateMicrocode = true;
        };
      };
    };
    boot = {
      kernelModules = ["kvm-intel"];
      kernelParams = ["i915.fastboot=1" "enable_gvt=1"];
    };
    environment = {
      systemPackages = [pkgs.intel-gpu-tools];
    };
  };
}
