{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.virtualisation.virt-manager;
  inherit (config.modules.users) user;
  iommu-check = pkgs.writeShellApplication {
    name = "iommu-check";
    runtimeInputs = [pkgs.pciutils];
    text = ''
      shopt -s nullglob
      for g in $(find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V); do
          echo "IOMMU Group ''${g##*/}:"
          for d in "$g/devices/"*; do
              echo -e "\t$(lspci -nns "''${d##*/}")"
          done;
      done;
    '';
  };
  ovmf =
    (pkgs.OVMF.override {
      secureBoot = true;
      tpmSupport = true;
    })
    .fd;
  qemu = pkgs.writeShellApplication {
    name = "qemu";
    text = ''
      set -e
      GUEST_NAME="$1"
      HOOK_NAME="$2"
      STATE_NAME="$3"
      BASEDIR="$(dirname "$0")"
      HOOKPATH="$BASEDIR/qemu.d/$GUEST_NAME/$HOOK_NAME/$STATE_NAME"
      if [ -f "$HOOKPATH" ] && [ -s "$HOOKPATH" ] && [ -x "$HOOKPATH" ]; then
        "$HOOKPATH" "$@"
      elif [ -d "$HOOKPATH" ]; then
        while read -r file; do
          if [ -n "$file" ]; then
            "$file" "$@"
          fi
        done <<< "$(find -L "$HOOKPATH" -maxdepth 1 -type f -executable -print;)"
      fi
    '';
  };
  qemu-start-hook = pkgs.writeShellApplication {
    name = "qemu-start-hook";
    runtimeInputs = [pkgs.mullvad];
    text = ''
      if [ "$1" = "win11" ] && [ "$2" = "prepare" ] && [ "$3" = "begin" ]; then
        mullvad disconnect
      fi
    '';
  };
  qemu-stop-hook = pkgs.writeShellApplication {
    name = "qemu-stop-hook";
    runtimeInputs = [pkgs.mullvad];
    text = ''
      if [ "$1" = "win11" ] && [ "$2" = "release" ] && [ "$3" = "end" ]; then
        mullvad connect
      fi
    '';
  };
  qemu-vnc-hook = pkgs.writeShellApplication {
    name = "qemu-vnc-hook";
    runtimeInputs = [pkgs.iptables];
    text = ''
      GUEST_IP="192.168.122.1"
      GUEST_PORT="5900"
      HOST_PORT="5900"
      if [ "$1" = "win11" ]; then
        iptables -A FORWARD -s 192.168.178.137/24 -d 192.168.122.0/24 -o virbr0 -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
        if [ "$2" = "stopped" ] || [ "$2" = "reconnect" ]; then
         iptables -D FORWARD -o virbr0 -p tcp -d "$GUEST_IP" --dport "$GUEST_PORT" -j ACCEPT
         iptables -t nat -D PREROUTING -p tcp --dport "$HOST_PORT" -j DNAT --to "$GUEST_IP:$GUEST_PORT"
        fi
        if [ "$2" = "start" ] || [ "$2" = "reconnect" ]; then
         iptables -I FORWARD -o virbr0 -p tcp -d "$GUEST_IP" --dport "$GUEST_PORT" -j ACCEPT
         iptables -t nat -I PREROUTING -p tcp --dport "$HOST_PORT" -j DNAT --to "$GUEST_IP:$GUEST_PORT"
        fi
      fi
    '';
  };
  qemu-mkdisk = pkgs.writeShellApplication {
    name = "qemu-mkdisk";
    runtimeInputs = [pkgs.qemu];
    text = ''
      DISK_PATH="/var/lib/libvirt/images/win11.qcow2"

      mkdir -p /var/lib/libvirt/images

      if [ -f "$DISK_PATH" ]; then
        exit 0
      else
        qemu-img create -f qcow2 "$DISK_PATH" 1T
        qemu-img info "$DISK_PATH"
      fi
    '';
  };
  qemu-run-windows-looking-glass = pkgs.writeShellApplication {
    name = "qemu-run-windows-looking-glass";
    runtimeInputs = [
      pkgs.mullvad
      pkgs.libvirt
      pkgs.looking-glass-client
    ];
    text = ''
      if ! mullvad status | grep -q "Disconnected"; then
        mullvad disconnect
      fi

      if ! virsh --connect qemu:///system domstate win11 | grep -q "running"; then
        virsh --connect qemu:///system start win11
      fi

      looking-glass-client
    '';
  };
  virtio-iso = pkgs.runCommand "virtio-win.iso" {} "${pkgs.cdrtools}/bin/mkisofs -l -V VIRTIO-WIN -o $out ${pkgs.virtio-win}";
in {
  imports = [inputs.nixvirt.nixosModules.default];
  options = {
    modules = {
      virtualisation = {
        virt-manager = {
          windows = {
            enable = lib.mkEnableOption "Enable a Windows VM" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.windows.enable) {
    boot = {
      kernelParams = [
        "amd_iommu=on"
        "iommu=pt"
      ];
      kernelModules = ["kvm-amd" "vfio_virqfd" "vfio_pci" "vfio" "vfio_iommu_type1"];
      extraModprobeConfig = ''
        options kvm_amd nested=1
        options vfio_iommu_type1 allow_unsafe_interrupts=1
        options vfio_pci disable_vga=1
      '';
      initrd = {
        availableKernelModules = ["amdgpu" "vfio-pci"];
        preDeviceCommands = ''
          for i in /sys/bus/pci/devices/*/boot_vga; do
              if [ $(cat "$i") -eq 0 ]; then
                  GPU=''${i%/boot_vga}
                  AUDIO="$(echo "$GPU" | sed -e "s/0$/1/")"
                  USB="$(echo "$GPU" | sed -e "s/0$/2/")"
                  echo "vfio-pci" > "$GPU/driver_override"
                  if [ -d "$AUDIO" ]; then
                      echo "vfio-pci" > "$AUDIO/driver_override"
                  fi
                  if [ -d "$USB" ]; then
                      echo "vfio-pci" > "$USB/driver_override"
                  fi
              fi
          done

          modprobe -i vfio-pci
        '';
      };
    };
    environment = {
      systemPackages = [
        pkgs.virt-manager
        pkgs.virt-viewer
        pkgs.spice
        pkgs.spice-gtk
        pkgs.spice-protocol
        pkgs.libguestfs
        pkgs.virtio-win
        pkgs.win-spice
        pkgs.looking-glass-client
        pkgs.scream
        iommu-check
        qemu-run-windows-looking-glass
      ];
    };
    home-manager = lib.mkIf (config.modules.home-manager.enable) {
      users = {
        ${user} = {
          xdg = {
            desktopEntries = {
              looking-glass-client = {
                name = "Windows 11™";
                type = "Application";
                exec = lib.getExe qemu-run-windows-looking-glass;
                icon = ./win11.png;
                noDisplay = false;
                startupNotify = true;
                terminal = false;
              };
            };
          };
          wayland = {
            windowManager = {
              hyprland = {
                extraConfig = ''
                  windowrule = content game,class:(looking-glass-client)
                  windowrule = fullscreen,class:(looking-glass-client)
                '';
              };
            };
          };
        };
      };
    };
    systemd = {
      services = {
        libvirtd = {
          preStart = ''
            mkdir -p /var/lib/libvirt/vgabios
            ln -sf ${qemu}/bin/qemu /var/lib/libvirt/hooks/qemu
            ${lib.getExe qemu-mkdisk}
          '';
        };
      };
      user.services.scream-ivshmem = {
        enable = true;
        description = "Scream IVSHMEM";
        serviceConfig = {
          ExecStart = "${pkgs.scream}/bin/scream -m /dev/shm/scream";
          Restart = "always";
        };
        wantedBy = ["multi-user.target"];
        requires = ["pulseaudio.service"];
      };
      tmpfiles = {
        rules = let
          firmware = pkgs.runCommandLocal "qemu-firmware" {} ''
            mkdir $out
            cp ${pkgs.qemu}/share/qemu/firmware/*.json $out
          '';
        in [
          "L+ /var/lib/qemu/firmware - - - - ${firmware}"
          "f /dev/shm/scream 0660 ${user} kvm -"
          "f /dev/shm/looking-glass 0660 ${user} kvm -"
        ];
      };
    };
    users = {
      users = {
        ${user} = {
          extraGroups = ["libvirtd" "libvirt" "kvm" "input"];
        };
      };
    };
    networking = {
      firewall = {
        allowedTCPPorts = [5900];
      };
      nat = {
        inherit (config.modules.virtualisation.virt-manager) enable;
        internalInterfaces = ["wlp17s0u4"];
        externalInterface = "virbr0";
        forwardPorts = [
          {
            destination = "192.168.122.1:5900";
            proto = "tcp";
            sourcePort = 5900;
          }
        ];
      };
    };
    virtualisation = {
      libvirtd = {
        onBoot = "ignore";
        onShutdown = "shutdown";
        allowedBridges = ["virbr0"];
        qemu = {
          runAsRoot = true;
          ovmf = {
            inherit (config.modules.virtualisation.virt-manager) enable;
            packages = [ovmf];
          };
        };
        hooks = {
          qemu = {
            start = lib.getExe qemu-start-hook;
            stop = lib.getExe qemu-stop-hook;
            vnc = lib.getExe qemu-vnc-hook;
          };
        };
      };
      libvirt = {
        inherit (config.modules.virtualisation) enable;
        swtpm = {
          inherit (config.modules.virtualisation) enable;
        };
        connections = {
          "qemu:///system" = {
            domains = [
              {
                definition = let
                  source_address = bus: slot: function: {
                    inherit bus slot function;
                    domain = 0;
                  };
                in
                  inputs.nixvirt.lib.domain.writeXML {
                    "xmlns:qemu" = "http://libvirt.org/schemas/domain/qemu/1.0";
                    "qemu:capabilities" = [
                      {
                        "qemu:del" = {
                          capability = "usb-host.hostdevice";
                        };
                      }
                    ];
                    type = "kvm";
                    name = "win11";
                    uuid = "99901f8b-8c80-9518-a6a1-2cf05dcd371e";
                    metadata = with inputs.nixvirt.lib.xml; [
                      (
                        elem "libosinfo:libosinfo" [
                          (attr "xmlns:libosinfo" "http://libosinfo.org/xmlns/libvirt/domain/1.0")
                        ]
                        [
                          (
                            elem "libosinfo:os" [
                              (attr "id" "http://microsoft.com/win/11")
                            ]
                            []
                          )
                        ]
                      )
                    ];
                    sysinfo = {
                      type = "smbios";
                      bios = {
                        entry = [
                          {
                            name = "vendor";
                            value = "American Megatrends Inc.";
                          }
                          {
                            name = "version";
                            value = "1.30";
                          }
                          {
                            name = "date";
                            value = "10/14/2020";
                          }
                          {
                            name = "release";
                            value = "5.17";
                          }
                        ];
                      };
                      system = {
                        entry = [
                          {
                            name = "manufacturer";
                            value = "Micro-Star International Co., Ltd.";
                          }
                          {
                            name = "product";
                            value = "MS-7C83";
                          }
                          {
                            name = "version";
                            value = "1.0";
                          }
                          {
                            name = "serial";
                            value = "Default string";
                          }
                          {
                            name = "uuid";
                            value = "99901f8b-8c80-9518-a6a1-2cf05dcd371e";
                          }
                          {
                            name = "sku";
                            value = "Default string";
                          }
                          {
                            name = "family";
                            value = "Default string";
                          }
                        ];
                      };
                      baseBoard = {
                        entry = [
                          {
                            name = "manufacturer";
                            value = "Micro-Star International Co., Ltd.";
                          }
                          {
                            name = "product";
                            value = "B460M PRO-VDH WIFI (MS-7C83)";
                          }
                          {
                            name = "version";
                            value = "1.0";
                          }
                          {
                            name = "serial";
                            value = "07C8310_KA1C078357";
                          }
                          {
                            name = "asset";
                            value = "Default string";
                          }
                        ];
                      };
                    };
                    memory = {
                      unit = "KiB";
                      count = 16777216 * 2;
                    };
                    currentMemory = {
                      unit = "KiB";
                      count = 16777216 * 2;
                    };
                    memoryBacking = {
                      source = {
                        type = "memfd";
                      };
                      access = {
                        mode = "shared";
                      };
                    };
                    vcpu = {
                      placement = "static";
                      count = 16;
                    };
                    os = {
                      hack = "efi";
                      type = "hvm";
                      arch = "x86_64";
                      machine = "pc-q35-9.0";
                      firmware = {
                        feature = [
                          {
                            enabled = false;
                            name = "enrolled-keys";
                          }
                          {
                            enabled = true;
                            name = "secure-boot";
                          }
                        ];
                      };
                      loader = {
                        readonly = true;
                        type = "pflash";
                        secure = true;
                        path = "${pkgs.qemu}/share/qemu/edk2-x86_64-secure-code.fd";
                      };
                      nvram = {
                        template = "${pkgs.qemu}/share/qemu/edk2-i386-vars.fd";
                        path = "/var/lib/libvirt/qemu/nvram/win11_VARS.fd";
                      };
                      bootmenu = {
                        enable = false;
                      };
                      smbios = {
                        mode = "sysinfo";
                      };
                    };
                    features = {
                      acpi = {};
                      apic = {};
                      hyperv = {
                        mode = "custom";
                        relaxed = {
                          state = true;
                        };
                        vapic = {
                          state = true;
                        };
                        spinlocks = {
                          state = true;
                          retries = 8191;
                        };
                        vpindex = {
                          state = true;
                        };
                        runtime = {
                          state = true;
                        };
                        synic = {
                          state = true;
                        };
                        stimer = {
                          state = true;
                          direct = {
                            state = true;
                          };
                        };
                        reset = {
                          state = true;
                        };
                        vendor_id = {
                          state = true;
                          value = "KVM Hv";
                        };
                        frequencies = {
                          state = true;
                        };
                        reenlightenment = {
                          state = true;
                        };
                        tlbflush = {
                          state = true;
                        };
                        ipi = {
                          state = true;
                        };
                        topoext = {
                          state = true;
                        };
                      };
                      kvm = {
                        hidden = {
                          state = true;
                        };
                      };
                      vmport = {
                        state = false;
                      };
                      ioapic = {
                        driver = "kvm";
                      };
                    };
                    cpu = {
                      mode = "host-passthrough";
                      check = "none";
                      migratable = true;
                      topology = {
                        sockets = 1;
                        dies = 1;
                        cores = 8;
                        threads = 2;
                      };
                      feature = [
                        {
                          policy = "disable";
                          name = "hypervisor";
                        }
                        {
                          policy = "require";
                          name = "vmx";
                        }
                        {
                          policy = "disable";
                          name = "mpx";
                        }
                        {
                          policy = "require";
                          name = "topoext";
                        }
                      ];
                    };
                    clock = {
                      offset = "localtime";
                      timer = [
                        {
                          name = "rtc";
                          tickpolicy = "catchup";
                        }
                        {
                          name = "pit";
                          tickpolicy = "delay";
                        }
                        {
                          name = "hpet";
                          present = false;
                        }
                        {
                          name = "hypervclock";
                          present = true;
                        }
                      ];
                    };
                    on_poweroff = "destroy";
                    on_reboot = "restart";
                    on_crash = "destroy";
                    pm = {
                      suspend-to-mem = {
                        enabled = false;
                      };
                      suspend-to-disk = {
                        enabled = false;
                      };
                    };
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
                          };
                          source = {
                            file = "/var/lib/libvirt/images/win11.qcow2";
                          };
                          target = {
                            dev = "sda";
                            bus = "sata";
                          };
                          boot = {
                            order = 1;
                          };
                        }
                        {
                          type = "file";
                          device = "cdrom";
                          driver = {
                            name = "qemu";
                            type = "raw";
                          };
                          source = {
                            file = "/var/lib/libvirt/images/win11.iso";
                            startupPolicy = "mandatory";
                          };
                          target = {
                            bus = "sata";
                            dev = "sdb";
                          };
                          boot = {
                            order = 2;
                          };
                          readonly = true;
                        }
                        {
                          type = "file";
                          device = "cdrom";
                          driver = {
                            name = "qemu";
                            type = "raw";
                          };
                          source = {
                            file = "${virtio-iso}";
                          };
                          target = {
                            bus = "sata";
                            dev = "sdc";
                          };
                          readonly = true;
                        }
                      ];
                      filesystem = [
                        {
                          type = "mount";
                          accessmode = "passthrough";
                          driver = {
                            type = "virtiofs";
                          };
                          source = {
                            dir = "/home/${user}/Public";
                          };
                          target = {
                            dir = "Public";
                          };
                        }
                      ];
                      interface = {
                        type = "bridge";
                        model = {
                          type = "virtio";
                        };
                        source = {
                          bridge = "virbr0";
                        };
                      };
                      shmem = {
                        name = "looking-glass";
                        model = {
                          type = "ivshmem-plain";
                        };
                        size = {
                          unit = "M";
                          count = 256;
                        };
                      };
                      channel = [
                        {
                          type = "spicevmc";
                          target = {
                            type = "virtio";
                            name = "com.redhat.spice.0";
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
                      tpm = {
                        model = "tpm-crb";
                        backend = {
                          type = "emulator";
                          version = "2.0";
                        };
                      };
                      graphics = [
                        {
                          type = "spice";
                          autoport = true;
                          listen = {
                            type = "address";
                            address = "127.0.0.1";
                          };
                          image = {
                            compression = false;
                          };
                          gl = {
                            enable = false;
                          };
                        }
                      ];
                      sound = {
                        model = "ich9";
                        audio = {
                          id = 1;
                        };
                      };
                      audio = {
                        id = 1;
                        type = "spice";
                      };
                      video = {
                        model = {
                          type = "none";
                        };
                      };
                      hostdev = [
                        {
                          mode = "subsystem";
                          type = "pci";
                          managed = true;
                          driver = {
                            name = "vfio";
                          };
                          source = {
                            address = source_address 5 0 0;
                          };
                          rom = {
                            bar = false;
                          };
                        }
                        {
                          mode = "subsystem";
                          type = "pci";
                          managed = true;
                          driver = {
                            name = "vfio";
                          };
                          source = {
                            address = source_address 5 0 1;
                          };
                          rom = {
                            bar = false;
                          };
                        }
                      ];
                      watchdog = {
                        model = "itco";
                        action = "reset";
                      };
                      memballoon = {
                        model = "none";
                      };
                    };
                  };
              }
            ];
            networks = [
              {
                definition = inputs.nixvirt.lib.network.writeXML {
                  name = "default";
                  uuid = "fd64df3b-30ed-495c-ba06-b2f292c10d92";
                  forward = {
                    mode = "nat";
                    nat = {
                      port = {
                        start = 1024;
                        end = 65535;
                      };
                    };
                  };
                  bridge = {
                    name = "virbr0";
                    stp = true;
                    delay = 0;
                  };
                  ip = {
                    address = "192.168.122.1";
                    netmask = "255.255.255.0";
                    dhcp = {
                      range = {
                        start = "192.168.122.2";
                        end = "192.168.122.254";
                      };
                    };
                  };
                };
                active = true;
              }
            ];
            pools = [
              {
                definition = inputs.nixvirt.lib.pool.writeXML {
                  name = "default";
                  uuid = "8c75fdf7-68e0-4089-8a34-0ab56c7c3c40";
                  type = "dir";
                  target = {
                    path = "/var/lib/libvirt/images";
                    permissions = {
                      mode = "0711";
                      owner = "0";
                      group = "0";
                    };
                  };
                };
              }
            ];
          };
        };
      };
    };
  };
}
