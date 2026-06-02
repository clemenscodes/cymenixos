{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.virtualisation;
  tcfg = cfg.distroLab;
  inherit (config.modules.users) user;

  # RTX 3080 passthrough target (same card the Windows VM uses): 03:00.0 + .1
  source_address = bus: slot: function: {
    inherit bus slot function;
    domain = 0;
  };

  # Deterministic, stable libvirt UUID derived from the domain name.
  mkUuid = s: let
    h = builtins.hashString "sha1" s;
  in
    lib.concatStringsSep "-" [
      (lib.substring 0 8 h)
      (lib.substring 8 4 h)
      (lib.substring 12 4 h)
      (lib.substring 16 4 h)
      (lib.substring 20 12 h)
    ];

  # Per-distro persistent qcow2 created on libvirtd start (idempotent). Both the
  # install and GPU variants of a distro share this one disk.
  mkDisk = name:
    pkgs.writeShellApplication {
      name = "qemu-mkdisk-${name}";
      runtimeInputs = [pkgs.qemu];
      text = ''
        DISK_PATH="/var/lib/libvirt/images/${name}.qcow2"
        mkdir -p /var/lib/libvirt/images
        if [ ! -f "$DISK_PATH" ]; then
          qemu-img create -f qcow2 "$DISK_PATH" ${tcfg.diskSize}
          qemu-img info "$DISK_PATH"
        fi
      '';
    };

  # gpu=false -> "<name>-install": virtio video + SPICE/VNC, NO passthrough.
  #              Install the distro AND its Nvidia driver here first.
  # gpu=true  -> "<name>": RTX 3080 passthrough, video=none (drives the physical
  #              monitor), host keyboard+mouse shared via evdev.
  # Both variants share the same qcow2 and the same UEFI nvram so the bootloader
  # entry written during install is seen by the GPU variant.
  mkDomain = name: iso: gpu: let
    vmName =
      if gpu
      then name
      else "${name}-install";

    base = {
      type = "kvm";
      name = vmName;
      uuid = mkUuid vmName;

      memory = {
        unit = "GiB";
        count = tcfg.memoryGiB;
      };
      currentMemory = {
        unit = "GiB";
        count = tcfg.memoryGiB;
      };

      # access.mode = shared is required for the virtiofs share.
      memoryBacking = {
        source.type = "memfd";
        access.mode = "shared";
      };

      vcpu = {
        placement = "static";
        count = tcfg.vcpus;
      };

      iothreads = {count = 1;};

      os = {
        type = "hvm";
        arch = "x86_64";
        machine = "pc-q35-9.0";
        # Plain (non-secure-boot) OVMF — distros with unsigned/custom kernels
        # (CachyOS, Nobara, Bazzite) boot cleanly without secure boot.
        loader = {
          readonly = true;
          type = "pflash";
          path = "${pkgs.qemu}/share/qemu/edk2-x86_64-code.fd";
        };
        nvram = {
          template = "${pkgs.qemu}/share/qemu/edk2-i386-vars.fd";
          # Shared per-distro (NOT per-variant) so install + GPU agree on boot.
          path = "/var/lib/libvirt/qemu/nvram/${name}_VARS.fd";
        };
        bootmenu.enable = true;
      };

      features = {
        acpi = {};
        apic = {};
      };

      cpu = {
        mode = "host-passthrough";
        check = "none";
        topology = {
          sockets = 1;
          dies = 1;
          cores = tcfg.vcpus;
          threads = 1;
        };
      };

      clock.offset = "utc";

      on_poweroff = "destroy";
      on_reboot = "restart";
      on_crash = "destroy";

      devices = {
        emulator = "/run/libvirt/nix-emulators/qemu-system-x86_64";

        disk = [
          {
            type = "file";
            device = "disk";
            driver = {
              name = "qemu";
              type = "qcow2";
              cache = "none";
              discard = "unmap";
              iothread = 1;
            };
            source.file = "/var/lib/libvirt/images/${name}.qcow2";
            target = {
              dev = "vda";
              bus = "virtio";
            };
            # GPU variant boots the installed disk first; install variant boots
            # the ISO first.
            boot.order =
              if gpu
              then 1
              else 2;
          }
          {
            type = "file";
            device = "cdrom";
            driver = {
              name = "qemu";
              type = "raw";
            };
            source = {
              file = "${tcfg.isoDir}/${iso}";
              startupPolicy = "optional";
            };
            target = {
              dev = "sda";
              bus = "sata";
            };
            readonly = true;
            boot.order =
              if gpu
              then 2
              else 1;
          }
        ];

        # virtiofs share: drop the AppImage in tcfg.shareDir on the host, then
        # `sudo mount -t virtiofs share /mnt` inside any guest.
        filesystem = [
          {
            type = "mount";
            accessmode = "passthrough";
            driver.type = "virtiofs";
            source.dir = tcfg.shareDir;
            target.dir = "share";
          }
        ];

        interface = {
          type = "network";
          model.type = "virtio";
          source.network = "default";
        };

        memballoon.model = "none";
      };
    };

    # GPU variant: passthrough + evdev input + no emulated display.
    gpuExtra = {
      "xmlns:qemu" = "http://libvirt.org/schemas/domain/qemu/1.0";
      # Share the host keyboard + mouse (toggle host<->guest with both Ctrl).
      "qemu:commandline" = {
        "qemu:arg" = [
          {value = "-object";}
          {value = "input-linux,id=kbd0,evdev=${tcfg.keyboard},grab_all=on,repeat=on";}
          {value = "-object";}
          {value = "input-linux,id=mouse0,evdev=${tcfg.mouse}";}
        ];
      };
      devices =
        base.devices
        // {
          hostdev = [
            {
              mode = "subsystem";
              type = "pci";
              managed = true;
              driver.name = "vfio";
              source.address = source_address 3 0 0;
              rom.bar = false;
            }
            {
              mode = "subsystem";
              type = "pci";
              managed = true;
              driver.name = "vfio";
              source.address = source_address 3 0 1;
            }
          ];
          # The passed-through 3080 drives the physical monitor.
          video.model.type = "none";
        };
    };

    # Install variant: ordinary viewable desktop (virt-viewer / virt-manager).
    installExtra = {
      devices =
        base.devices
        // {
          video.model.type = "virtio";
          graphics = [
            {
              type = "spice";
              autoport = true;
              listen = {
                type = "address";
                address = "127.0.0.1";
              };
              gl.enable = false;
            }
            {
              type = "vnc";
              port = -1;
              autoport = true;
              listen = {
                type = "address";
                address = "127.0.0.1";
              };
            }
          ];
          input = [
            {
              type = "mouse";
              bus = "virtio";
            }
            {
              type = "keyboard";
              bus = "virtio";
            }
          ];
          channel = [
            {
              type = "spicevmc";
              target = {
                type = "virtio";
                name = "com.redhat.spice.0";
              };
            }
          ];
        };
    };
  in {
    definition = inputs.nixvirt.lib.domain.writeXML (
      base
      // (
        if gpu
        then gpuExtra
        else installExtra
      )
    );
  };

  # Two domains per distro: "<name>-install" and "<name>".
  domains =
    lib.concatLists (
      lib.mapAttrsToList (name: iso: [
        (mkDomain name iso false)
        (mkDomain name iso true)
      ])
      tcfg.distros
    );

  mkdisks = lib.mapAttrsToList (name: _: mkDisk name) tcfg.distros;
in {
  options = {
    modules = {
      virtualisation = {
        distroLab = {
          enable =
            lib.mkEnableOption "GPU-passthrough Linux distro VMs (install + GPU variants) for AppImage testing"
            // {default = false;};
          keyboard = lib.mkOption {
            type = lib.types.str;
            default = "/dev/input/by-id/usb-Wooting_Wooting_60HE+_A02B2501W05T02100S02H15106-if01-event-kbd";
            description = "evdev keyboard passed to the GPU variants (shared via both-Ctrl toggle).";
          };
          mouse = lib.mkOption {
            type = lib.types.str;
            default = "/dev/input/by-id/usb-Razer_Razer_Viper_V3_Pro-event-mouse";
            description = "evdev mouse passed to the GPU variants.";
          };
          shareDir = lib.mkOption {
            type = lib.types.str;
            default = "/home/${user}/Public";
            description = "Host directory exposed to every guest over virtiofs (drop the AppImage here). Defaults to ~/Public, the same folder the Windows VM shares.";
          };
          isoDir = lib.mkOption {
            type = lib.types.str;
            default = "/home/${user}/Public/isos";
            description = "Host directory holding the installer ISOs referenced by the distros (XDG_ISO_DIR).";
          };
          memoryGiB = lib.mkOption {
            type = lib.types.int;
            default = 12;
            description = "RAM per test VM in GiB.";
          };
          vcpus = lib.mkOption {
            type = lib.types.int;
            default = 8;
            description = "vCPU count per test VM.";
          };
          diskSize = lib.mkOption {
            type = lib.types.str;
            default = "80G";
            description = "Per-distro qcow2 virtual size (sparse).";
          };
          distros = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = {
              cachyos = "cachyos.iso";
              bazzite = "bazzite.iso";
              nobara = "nobara.iso";
              mint = "mint.iso";
              ubuntu = "ubuntu.iso";
            };
            description = "Map of VM name -> installer ISO filename (inside isoDir).";
          };
        };
      };
    };
  };

  config = lib.mkIf (cfg.enable && cfg.virt-manager.enable && tcfg.enable) {
    assertions = [
      {
        assertion = cfg.virt-manager.vfio.enable;
        message = "modules.virtualisation.distroLab requires modules.virtualisation.virt-manager.vfio.enable (the RTX 3080 must be vfio-bound for GPU passthrough).";
      }
    ];

    systemd.tmpfiles.rules = [
      "d ${tcfg.shareDir} 0755 ${user} ${user} -"
      "d ${tcfg.isoDir} 0755 ${user} ${user} -"
    ];

    systemd.services.libvirtd.preStart = lib.mkAfter (
      lib.concatMapStringsSep "\n" (s: lib.getExe s) mkdisks
    );

    virtualisation.libvirt.connections."qemu:///system".domains = domains;
  };
}
