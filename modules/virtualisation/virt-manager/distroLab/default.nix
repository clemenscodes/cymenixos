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

  # Three phases per distro, all sharing one qcow2 + one UEFI nvram:
  #   "install" -> "<name>-install": SPICE, boots the ISO. Install the OS.
  #   "setup"   -> "<name>-setup":   SPICE, boots the installed disk (no GPU).
  #                Install the Nvidia driver + do post-install config here.
  #   "gpu"     -> "<name>":         RTX 3080 passthrough, video=none (physical
  #                monitor), host keyboard+mouse via evdev. Run the AppImage.
  mkDomain = name: iso: variant: let
    isGpu = variant == "gpu";
    # Only the install phase boots the ISO first; setup/gpu boot the disk.
    bootIso = variant == "install";
    vmName =
      if isGpu
      then name
      else "${name}-${variant}";

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
            # install boots the ISO first; setup/gpu boot the installed disk.
            boot.order =
              if bootIso
              then 2
              else 1;
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
              if bootIso
              then 1
              else 2;
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

    # GPU variant: 3080 passed through as the PRIMARY display (→ Elgato,
    # video=none) and the host keyboard+mouse passed through via evdev — real,
    # no compromises. ESCAPE HATCHES if the grab toggle ever misbehaves (so you
    # NEVER pull power again): Alt+SysRq+E (kernel-level, works even mid-grab) or
    # `ssh <host> distrolab-release` from your phone (surgical — frees input,
    # keeps your session).
    gpuExtra = {
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
          video.model.type = "none";
          input = [
            {
              type = "evdev";
              source = {
                dev = tcfg.keyboard;
                grab = "all";
                grabToggle = tcfg.grabToggle;
                repeat = true;
              };
            }
            {
              type = "evdev";
              source.dev = tcfg.mouse;
            }
          ];
        };
    };

    # install + setup phases: ordinary viewable SPICE/VNC desktop (no GPU).
    spiceExtra = {
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
        if isGpu
        then gpuExtra
        else spiceExtra
      )
    );
  };

  # Three domains per distro: "<name>-install", "<name>-setup", "<name>".
  domains =
    lib.concatLists (
      lib.mapAttrsToList (name: iso: [
        (mkDomain name iso "install")
        (mkDomain name iso "setup")
        (mkDomain name iso "gpu")
      ])
      tcfg.distros
    );

  # Emergency get-my-devices-back: stops any running GPU VM, which releases the
  # evdev grab and returns the keyboard/mouse to the host. Run it out-of-band:
  # `ssh <host> distrolab-release` from your phone, or after Alt+SysRq+E.
  distrolab-release = pkgs.writeShellApplication {
    name = "distrolab-release";
    runtimeInputs = [pkgs.libvirt];
    text = ''
      for vm in ${lib.concatStringsSep " " (lib.attrNames tcfg.distros)}; do
        if virsh --connect qemu:///system domstate "$vm" 2>/dev/null | grep -q running; then
          echo "stopping $vm to release your keyboard/mouse..."
          virsh --connect qemu:///system destroy "$vm"
        fi
      done
    '';
  };

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
            # xremap grabs the physical Wooting and re-emits a VIRTUAL keyboard;
            # that virtual device is what actually carries keystrokes, so it's
            # what the VM must grab. Grabbing the raw Wooting fights xremap and
            # the release toggle never sees your keys. The udev rule below pins
            # the xremap virtual device to this stable symlink.
            default = "/dev/input/xremap-kbd";
            description = "evdev keyboard passed to the GPU variants — the xremap virtual keyboard (the real source of keystrokes on this host).";
          };
          mouse = lib.mkOption {
            type = lib.types.str;
            default = "/dev/input/by-id/usb-Razer_Razer_Viper_V3_Pro-event-mouse";
            description = "evdev mouse passed to the GPU variants.";
          };
          grabToggle = lib.mkOption {
            type = lib.types.enum ["ctrl-ctrl" "alt-alt" "shift-shift" "meta-meta" "scrolllock" "ctrl-scrolllock"];
            default = "shift-shift";
            description = "Key combo that toggles the evdev keyboard+mouse grab between host and guest. shift-shift (both Shift keys) works on 60% boards that lack Right Ctrl.";
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

    environment.systemPackages = [distrolab-release];

    # xremap re-emits your keystrokes through a virtual input device; give it a
    # stable symlink so the GPU VM grabs the node that actually carries keys
    # (and so the ctrl-ctrl release toggle works — it was failing because we
    # were grabbing the raw, xremap-owned Wooting instead).
    services.udev.extraRules = ''
      SUBSYSTEM=="input", KERNEL=="event*", ATTRS{name}=="xremap", ENV{ID_INPUT_KEYBOARD}=="1", SYMLINK+="input/xremap-kbd"
    '';

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
