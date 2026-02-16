{
  inputs,
  pkgs,
  lib,
  cymenixos,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.virtualisation.virt-manager;
  inherit (config.modules.users) user;
  vmConfig = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit system;
      inherit (cymenixos) inputs;
      inherit (cymenixos.inputs) nixpkgs;
      self = cymenixos;
    };
    modules = [
      ({
        inputs,
        config,
        system,
        ...
      }: {
        imports = [
          (import "${cymenixos}/modules" {inherit inputs pkgs lib cymenixos;})
          inputs.mtkwifi.nixosModules.mt7927
        ];
        environment = {
          systemPackages = with pkgs; [
            spice
            spice-gtk
            spice-protocol
            libguestfs
            scream
          ];
        };
        mt7927 = {
          enable = true;
        };
        modules = {
          enable = true;
          machine = {
            kind = "desktop";
            name = "desktop";
          };
          hostname = {
            enable = true;
            defaultHostname = "amaru";
          };
          users = {
            enable = true;
            wheel = true;
            user = "vm";
          };
          locale = {
            enable = true;
            defaultLocale = "de";
          };
          time = {
            enable = true;
            defaultTimeZone = "Europe/Berlin";
          };
          fonts = {
            enable = true;
            defaultFont = "Lilex Nerd Font";
            size = 12;
          };
          config = {
            enable = true;
            nix = {
              enable = true;
            };
          };
          disk = {
            enable = true;
            device = "/dev/vda";
            luksDisk = "luks";
            swapsize = 96;
          };
          boot = {
            enable = true;
            biosSupport = true;
            efiSupport = true;
            libreboot = false;
            inherit (config.modules.disk) device;
            hibernation = false;
            swapResumeOffset = 533760;
          };
          cpu = {
            enable = true;
            vendor = "amd";
            amd = {
              enable = true;
            };
            msr = {
              enable = true;
            };
          };
          gpu = {
            enable = true;
            nvidia = {
              enable = true;
            };
          };
          display = {
            enable = true;
            gui = "wayland";
            hyprland = {
              enable = true;
            };
            gtk = {
              enable = true;
            };
            qt = {
              enable = true;
            };
            sddm = {
              enable = true;
            };
          };
          ai = {
            enable = true;
          };
          rgb = {
            enable = false;
          };
          home-manager = {
            enable = true;
          };
          io = {
            enable = true;
            sound = {
              enable = true;
            };
            udisks = {
              enable = true;
            };
            xremap = {
              enable = true;
            };
          };
          networking = {
            enable = true;
            bluetooth = {
              enable = true;
            };
            dbus = {
              enable = true;
            };
            firewall = {
              enable = true;
            };
            wireless = {
              enable = true;
            };
          };
          security = {
            enable = true;
            gnupg = {
              enable = true;
            };
            polkit = {
              enable = true;
            };
            rtkit = {
              enable = true;
            };
            sudo = {
              enable = true;
              noPassword = true;
            };
            tpm = {
              enable = true;
            };
          };
          shell = {
            enable = true;
            console = {
              enable = true;
            };
            environment = {
              enable = true;
            };
            ld = {
              enable = true;
            };
            zsh = {
              enable = true;
            };
          };
          themes = {
            enable = true;
            catppuccin = {
              enable = true;
              flavor = "macchiato";
              accent = "blue";
            };
          };
          xdg = {
            enable = true;
          };
        };
        home-manager = {
          users = {
            ${config.modules.users.user} = {
              wayland = {
                windowManager = {
                  hyprland = {
                    extraConfig = ''
                      monitorv2 {
                        output = Virtual-1
                        mode = 3840x2160@60
                        position = 0x0
                        scale = 1
                      }
                    '';
                  };
                };
              };
              modules = {
                enable = true;
                browser = {
                  enable = true;
                  defaultBrowser = "brave";
                  chromium = {
                    enable = true;
                  };
                };
                display = {
                  enable = true;
                  cursor = {
                    enable = true;
                  };
                  gtk = {
                    enable = true;
                  };
                  imageviewer = {
                    enable = true;
                    defaultImageViewer = "swayimg";
                    swayimg = {
                      enable = true;
                    };
                  };
                  bar = {
                    enable = true;
                    waybar = {
                      enable = true;
                    };
                  };
                  compositor = {
                    enable = true;
                    hyprland = {
                      enable = true;
                      hyprpicker = {
                        enable = true;
                      };
                    };
                  };
                  launcher = {
                    enable = true;
                    defaultLauncher = "anyrun";
                    rofi = {
                      enable = true;
                    };
                    anyrun = {
                      enable = true;
                    };
                  };
                  pdfviewer = {
                    enable = true;
                    defaultPdfViewer = "zathura";
                    zathura = {
                      enable = true;
                    };
                  };
                  qt = {
                    enable = true;
                  };
                  screenshots = {
                    enable = true;
                  };
                };
                editor = {
                  enable = true;
                  defaultEditor = "nvim";
                  nvim = {
                    enable = true;
                  };
                  vscode = {
                    enable = true;
                  };
                };
                explorer = {
                  enable = true;
                  defaultExplorer = "yazi";
                  yazi = {
                    enable = true;
                  };
                };
                fonts = {
                  enable = true;
                };
                monitoring = {
                  enable = true;
                  btop = {
                    enable = true;
                  };
                  ncdu = {
                    enable = true;
                  };
                };
                networking = {
                  enable = true;
                  bluetooth = {
                    enable = true;
                    blueman = {
                      enable = true;
                    };
                  };
                  nm = {
                    enable = true;
                  };
                };
                security = {
                  enable = true;
                };
                shell = {
                  enable = true;
                  nom = {
                    enable = true;
                  };
                  nvd = {
                    enable = true;
                  };
                  starship = {
                    enable = true;
                  };
                  zoxide = {
                    enable = true;
                  };
                  zsh = {
                    enable = true;
                  };
                };
                terminal = {
                  enable = true;
                  defaultTerminal = "kitty";
                  kitty = {
                    enable = true;
                  };
                };
                utils = {
                  enable = true;
                  bat = {
                    enable = true;
                  };
                  fzf = {
                    enable = true;
                  };
                  nix-prefetch-git = {
                    enable = true;
                  };
                  nix-prefetch-github = {
                    enable = true;
                  };
                  lsusb = {
                    enable = true;
                  };
                  wget = {
                    enable = true;
                  };
                  gparted = {
                    enable = true;
                  };
                  ripgrep = {
                    enable = true;
                  };
                  tldr = {
                    enable = true;
                  };
                  unzip = {
                    enable = true;
                  };
                  zip = {
                    enable = true;
                  };
                };
                xdg = {
                  enable = true;
                };
              };
            };
          };
        };
      })
      (import "${cymenixos}/modules/iso" {inherit inputs pkgs lib;})
      ({...}: {
        modules = {
          iso = {
            enable = true;
            fast = true;
          };
        };
      })
    ];
  };

  vmIso = vmConfig.config.system.build.isoImage;
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
    home-manager = {
      users = {
        ${config.modules.users.user} = {
          virtualisation = {
            libvirt = {
              connections = {
                "qemu:///session" = let
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
                        type = "sdl";
                        gl.enable = true;
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
                          video.model.acceleration.accel3d = true;
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
                            file = "${vmIso}/iso/${vmIso.isoName}";
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
      };
    };
  };
}
