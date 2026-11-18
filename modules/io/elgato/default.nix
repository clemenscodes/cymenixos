{
  inputs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.io;
  inherit (config.modules.users) user;
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfree = true;
    };
  };
  sc0710 = config.boot.kernelPackages.callPackage ./sc0710.nix {};
  sc0710-cli = pkgs.callPackage ./sc0710-cli.nix {};
  sc0710-firmware = pkgs.callPackage ./sc0710-firmware.nix {};
  # The driver allocates its DMA chains with dma_alloc_coherent at every STREAMON. In an identity
  # domain (iommu=pt) that needs physically contiguous segments, and once the memory of the host is
  # fragmented, for example by a guest that pins its RAM, every start of a stream fails with -12 until
  # the memory is compacted. A translating domain maps the chains from any pages. Only the IOMMU group
  # of the card changes, every other device keeps the domain of the boot. The group takes its type
  # only while no driver is bound, so the module never autoloads the driver: udev sets the type when
  # the card appears and loads the driver after it.
  domainProgram = pkgs.writeShellScript "sc0710-translated-domain" ''
    device=/sys/bus/pci/devices/$1
    group=$(${pkgs.coreutils}/bin/readlink -f "$device/iommu_group")
    if [ -e "$group/type" ] && [ "$(${pkgs.coreutils}/bin/cat "$group/type")" != DMA-FQ ]; then
      if [ -e "$device/driver" ]; then
        echo "$1" > "$device/driver/unbind"
      fi
      echo DMA-FQ > "$group/type"
    fi
    /run/current-system/sw/bin/modprobe sc0710
    if [ ! -e "$device/driver" ]; then
      echo "$1" > /sys/bus/pci/drivers_probe
    fi
  '';
in {
  options = {
    modules = {
      io = {
        elgato = {
          enable =
            lib.mkEnableOption "Enable YUAN/Elgato sc0710 PCIe capture card driver (12ab:0710)"
            // {
              default = false;
            };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.elgato.enable) {
    boot = {
      extraModulePackages = [sc0710];
      blacklistedKernelModules = ["sc0710"];
    };
    services = {
      udev = {
        extraRules = ''
          ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x12ab", ATTR{device}=="0x0710", RUN+="${domainProgram} %k"
        '';
      };
    };
    hardware = {
      firmware = [sc0710-firmware];
    };
    environment = {
      systemPackages = [
        pkgs.v4l-utils
        pkgs.ffmpeg
        sc0710-cli
      ];
    };
    users = {
      users = {
        ${user} = {
          extraGroups = ["video"];
        };
      };
    };
  };
}
