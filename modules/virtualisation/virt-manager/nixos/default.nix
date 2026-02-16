{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules.virtualisation.virt-manager;
  inherit (config.modules.users) user;

  qemu-run-nixos-looking-glass = pkgs.writeShellApplication {
    name = "qemu-run-nixos-looking-glass";
    runtimeInputs = [
      pkgs.libvirt
      pkgs.looking-glass-client
    ];
    text = ''
      if ! virsh --connect qemu:///system domstate nixos | grep -q "running"; then
        virsh --connect qemu:///system start nixos
      fi

      __NV_DISABLE_EXPLICIT_SYNC=1 looking-glass-client -f /dev/shm/looking-glass
    '';
  };
in {
  options = {
    modules = {
      virtualisation = {
        virt-manager = {
          nixos = {
            enable = lib.mkEnableOption "Enable a NixOS VM" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.nixos.enable) {
    environment = {
      systemPackages = [
        qemu-run-nixos-looking-glass
      ];
    };

    home-manager = lib.mkIf (config.modules.home-manager.enable) {
      users = {
        ${user} = {
          xdg = {
            desktopEntries = {
              nixos = {
                name = "NixOS™";
                type = "Application";
                exec = lib.getExe qemu-run-nixos-looking-glass;
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                noDisplay = false;
                startupNotify = true;
                terminal = false;
              };
            };
          };
        };
      };
    };

    virtualisation = {
      libvirt = {
        connections = {
          "qemu:///system" = let
            source_address = bus: slot: function: {
              inherit bus slot function;
              domain = 0;
            };

            commonMetadata = uuid:
              with inputs.nixvirt.lib.xml; [
                (elem "libosinfo:libosinfo"
                  [(attr "xmlns:libosinfo" "http://libosinfo.org/xmlns/libvirt/domain/1.0")]
                  [
                    (
                      elem "libosinfo:os"
                      [(attr "id" "http://nixos.org/nixos/unstable")]
                      []
                    )
                  ])
              ];

            commonSysinfo = uuid: {
              type = "smbios";
              bios.entry = [
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
              system.entry = [
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
                  value = uuid;
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
              baseBoard.entry = [
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

            commonCPU = {
              mode = "host-passthrough";
              check = "none";
              migratable = false;
              topology = {
                sockets = 1;
                dies = 1;
                cores = 8;
                threads = 2;
              };
              cache.mode = "passthrough";
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
                {
                  policy = "require";
                  name = "invtsc";
                }
              ];
            };

            commonClock = {
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
                  name = "kvmclock";
                  present = false;
                }
                {
                  name = "hypervclock";
                  present = true;
                }
              ];
            };

            commonFeatures = {
              acpi = {};
              apic = {};
              hyperv = {
                mode = "custom";
                relaxed.state = true;
                vapic.state = true;
                spinlocks = {
                  state = true;
                  retries = 8191;
                };
                vpindex.state = true;
                runtime.state = true;
                synic.state = true;
                stimer = {
                  state = true;
                  direct.state = true;
                };
                reset.state = true;
                vendor_id = {
                  state = true;
                  value = "KVM Hv";
                };
                frequencies.state = true;
                reenlightenment.state = true;
                tlbflush.state = true;
                ipi.state = true;
                topoext.state = true;
              };
              kvm.hidden.state = true;
              vmport.state = false;
              ioapic.driver = "kvm";
            };

            commonDevices = {
              emulator = "/run/libvirt/nix-emulators/qemu-system-x86_64";

              filesystem = [
                {
                  type = "mount";
                  accessmode = "passthrough";
                  driver.type = "virtiofs";
                  source.dir = "/home/${user}/Public";
                  target.dir = "Public";
                }
              ];

              interface = {
                type = "network";
                model.type = "virtio";
                source.network = "default";
              };

              shmem = {
                name = "looking-glass";
                model.type = "ivshmem-plain";
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
                  image.compression = false;
                  gl.enable = false;
                }
                {
                  type = "vnc";
                  port = -1;
                  autoport = true;
                  hack = "0.0.0.0";
                  listen = {
                    type = "address";
                    address = "0.0.0.0";
                  };
                }
              ];

              sound = {
                model = "ich9";
                audio.id = 1;
              };
              audio = {
                id = 1;
                type = "spice";
              };
              watchdog = {
                model = "itco";
                action = "reset";
              };
              memballoon = {model = "none";};
            };

            mkDomain = {
              name,
              uuid,
              disks,
              videoModel,
              includeHostdev ? false,
            }: {
              definition = inputs.nixvirt.lib.domain.writeXML {
                "xmlns:qemu" = "http://libvirt.org/schemas/domain/qemu/1.0";
                "qemu:capabilities" = [
                  {"qemu:del".capability = "usb-host.hostdevice";}
                ];

                type = "kvm";
                inherit name uuid;

                metadata = commonMetadata uuid;
                sysinfo = commonSysinfo uuid;

                memory = {
                  unit = "KiB";
                  count = 16777216 * 2;
                };
                currentMemory = {
                  unit = "KiB";
                  count = 16777216 * 2;
                };

                memoryBacking = {
                  source.type = "memfd";
                  access.mode = "shared";
                };

                vcpu = {
                  placement = "static";
                  count = 16;
                };

                numatune.memory = {
                  mode = "strict";
                  nodeset = "0";
                };

                cputune.vcpupin =
                  builtins.genList
                  (
                    i: let
                      half = builtins.div i 2;
                      isEven = i == builtins.mul half 2;
                    in {
                      vcpu = i;
                      cpuset =
                        if isEven
                        then toString half
                        else toString (16 + half);
                    }
                  )
                  16;

                os = {
                  hack = "efi";
                  type = "hvm";
                  arch = "x86_64";
                  machine = "pc-q35-9.0";
                  firmware.feature = [
                    {
                      enabled = false;
                      name = "enrolled-keys";
                    }
                    {
                      enabled = true;
                      name = "secure-boot";
                    }
                  ];
                  loader = {
                    readonly = true;
                    type = "pflash";
                    secure = true;
                    path = "${pkgs.qemu}/share/qemu/edk2-x86_64-secure-code.fd";
                  };
                  nvram = {
                    template = "${pkgs.qemu}/share/qemu/edk2-i386-vars.fd";
                    path = "/var/lib/libvirt/qemu/nvram/nixos_VARS.fd";
                  };
                  bootmenu.enable = false;
                  smbios.mode = "host";
                };

                features = commonFeatures;
                cpu = commonCPU;
                clock = commonClock;

                on_poweroff = "destroy";
                on_reboot = "restart";
                on_crash = "destroy";

                pm = {
                  suspend-to-mem.enabled = false;
                  suspend-to-disk.enabled = false;
                };

                devices =
                  commonDevices
                  // {
                    disk = disks;
                    video.model.type = videoModel;
                  }
                  // (
                    if includeHostdev
                    then {
                      hostdev = [
                        {
                          mode = "subsystem";
                          type = "pci";
                          managed = true;
                          source.address = source_address 10 0 0;
                        }
                      ];
                    }
                    else {}
                  );
              };
            };
          in {
            domains = [
              (mkDomain {
                name = "nixos";
                uuid = "99901f8b-8c80-9518-a6a1-2cf05dcd3721";
                includeHostdev = true;
                videoModel = "virtio";
                disks = [
                  {
                    type = "file";
                    device = "cdrom";
                    driver = {
                      name = "qemu";
                      type = "raw";
                    };
                    source = {
                      file = null;
                      startupPolicy = "mandatory";
                    };
                    target = {
                      bus = "sata";
                      dev = "sdb";
                    };
                    boot.order = 1;
                    readonly = true;
                  }
                  {
                    type = "file";
                    device = "disk";
                    driver = {
                      name = "qemu";
                      type = "qcow2";
                      cache = "none";
                      discard = "unmap";
                    };
                    source.file = "/var/lib/libvirt/images/nixos.qcow2";
                    target = {
                      dev = "sda";
                      bus = "sata";
                    };
                    boot.order = 2;
                  }
                ];
              })
            ];
          };
        };
      };
    };
  };
}
