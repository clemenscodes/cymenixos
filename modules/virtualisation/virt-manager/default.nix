{
  inputs,
  pkgs,
  lib,
  cymenixos,
  ...
}: {config, ...}: let
  cfg = config.modules.virtualisation;
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

  qemu-mkdisk-win = pkgs.writeShellApplication {
    name = "qemu-mkdisk-win";
    runtimeInputs = [pkgs.qemu];
    text = ''
      DISK_PATH="/var/lib/libvirt/images/win11.qcow2"

      mkdir -p /var/lib/libvirt/images

      if [ -f "$DISK_PATH" ]; then
        exit 0
      else
        qemu-img create -f qcow2 "$DISK_PATH" 4T
        qemu-img info "$DISK_PATH"
      fi
    '';
  };

  qemu-mkdisk-nixos = pkgs.writeShellApplication {
    name = "qemu-mkdisk-nixos";
    runtimeInputs = [pkgs.qemu];
    text = ''
      DISK_PATH="/var/lib/libvirt/images/nixos.qcow2"

      mkdir -p /var/lib/libvirt/images

      if [ -f "$DISK_PATH" ]; then
        exit 0
      else
        qemu-img create -f qcow2 "$DISK_PATH" 4T
        qemu-img info "$DISK_PATH"
      fi
    '';
  };

  qemu-start-hook = pkgs.writeShellApplication {
    name = "qemu-start-hook";
    runtimeInputs = [pkgs.mullvad];
    text = ''
      if [ "$1" = "nixos" ] && [ "$2" = "prepare" ] && [ "$3" = "begin" ]; then
        echo "start hook $1 $2 $3"
      fi
      if [ "$1" = "win11" ] && [ "$2" = "prepare" ] && [ "$3" = "begin" ]; then
        echo "start hook $1 $2 $3"
      fi
      if [ "$1" = "win11-install" ] && [ "$2" = "prepare" ] && [ "$3" = "begin" ]; then
        echo "start hook $1 $2 $3"
      fi
      if [ "$1" = "win11-display" ] && [ "$2" = "prepare" ] && [ "$3" = "begin" ]; then
        echo "start hook $1 $2 $3"
      fi
    '';
  };

  qemu-stop-hook = pkgs.writeShellApplication {
    name = "qemu-stop-hook";
    runtimeInputs = [pkgs.mullvad];
    text = ''
      if [ "$1" = "nixos" ] && [ "$2" = "release" ] && [ "$3" = "end" ]; then
        echo "stop hook $1 $2 $3"
      fi
      if [ "$1" = "win11" ] && [ "$2" = "release" ] && [ "$3" = "end" ]; then
        echo "stop hook $1 $2 $3"
      fi
      if [ "$1" = "win11-install" ] && [ "$2" = "release" ] && [ "$3" = "end" ]; then
        echo "stop hook $1 $2 $3"
      fi
      if [ "$1" = "win11-display" ] && [ "$2" = "release" ] && [ "$3" = "end" ]; then
        echo "stop hook $1 $2 $3"
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
      if [ "$1" = "nixos" ]; then
        iptables -A FORWARD -s 192.168.178.135/24 -d 192.168.122.0/24 -o virbr0 -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
        if [ "$2" = "stopped" ] || [ "$2" = "reconnect" ]; then
         iptables -D FORWARD -o virbr0 -p tcp -d "$GUEST_IP" --dport "$GUEST_PORT" -j ACCEPT
         iptables -t nat -D PREROUTING -p tcp --dport "$HOST_PORT" -j DNAT --to "$GUEST_IP:$GUEST_PORT"
        fi
        if [ "$2" = "start" ] || [ "$2" = "reconnect" ]; then
         iptables -I FORWARD -o virbr0 -p tcp -d "$GUEST_IP" --dport "$GUEST_PORT" -j ACCEPT
         iptables -t nat -I PREROUTING -p tcp --dport "$HOST_PORT" -j DNAT --to "$GUEST_IP:$GUEST_PORT"
        fi
      fi
      if [ "$1" = "win11" ]; then
        iptables -A FORWARD -s 192.168.178.135/24 -d 192.168.122.0/24 -o virbr0 -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
        if [ "$2" = "stopped" ] || [ "$2" = "reconnect" ]; then
         iptables -D FORWARD -o virbr0 -p tcp -d "$GUEST_IP" --dport "$GUEST_PORT" -j ACCEPT
         iptables -t nat -D PREROUTING -p tcp --dport "$HOST_PORT" -j DNAT --to "$GUEST_IP:$GUEST_PORT"
        fi
        if [ "$2" = "start" ] || [ "$2" = "reconnect" ]; then
         iptables -I FORWARD -o virbr0 -p tcp -d "$GUEST_IP" --dport "$GUEST_PORT" -j ACCEPT
         iptables -t nat -I PREROUTING -p tcp --dport "$HOST_PORT" -j DNAT --to "$GUEST_IP:$GUEST_PORT"
        fi
      fi
      if [ "$1" = "win11-install" ]; then
        iptables -A FORWARD -s 192.168.178.135/24 -d 192.168.122.0/24 -o virbr0 -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
        if [ "$2" = "stopped" ] || [ "$2" = "reconnect" ]; then
         iptables -D FORWARD -o virbr0 -p tcp -d "$GUEST_IP" --dport "$GUEST_PORT" -j ACCEPT
         iptables -t nat -D PREROUTING -p tcp --dport "$HOST_PORT" -j DNAT --to "$GUEST_IP:$GUEST_PORT"
        fi
        if [ "$2" = "start" ] || [ "$2" = "reconnect" ]; then
         iptables -I FORWARD -o virbr0 -p tcp -d "$GUEST_IP" --dport "$GUEST_PORT" -j ACCEPT
         iptables -t nat -I PREROUTING -p tcp --dport "$HOST_PORT" -j DNAT --to "$GUEST_IP:$GUEST_PORT"
        fi
      fi
      if [ "$1" = "win11-display" ]; then
        iptables -A FORWARD -s 192.168.178.135/24 -d 192.168.122.0/24 -o virbr0 -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
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
in {
  imports = [
    inputs.nixvirt.nixosModules.default
    (import ./nixos {inherit inputs pkgs lib cymenixos;})
    (import ./windows {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      virtualisation = {
        virt-manager = {
          enable = lib.mkEnableOption "Enable virt-manager" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.virt-manager.enable) {
    boot = {
      initrd = {
        availableKernelModules = ["vfio-pci"];
        kernelModules = [
          "vfio_pci"
          "vfio"
          "vfio_iommu_type1"
          "kvmfr"
        ];
      };
      kernelParams = [
        "amd_iommu=on"
        "iommu=pt"
        "isolcpus=0-7,16-23"
        "nohz_full=0-7,16-23"
        "rcu_nocbs=0-7,16-23"
        "kvmfr.static_size_mb=256"
        "pcie_acs_override=downstream,multifunction"
      ];
      kernelModules = [
        "kvm-amd"
      ];
      extraModprobeConfig = ''
        options kvm_amd nested=1
        options vfio_iommu_type1 allow_unsafe_interrupts=1
        options vfio_pci disable_vga=1
        options vfio-pci ids=10de:2206,10de:1aef,14c3:7927
      '';
      extraModulePackages = [config.boot.kernelPackages.kvmfr];
    };

    systemd = {
      services = {
        libvirtd = {
          preStart = ''
            mkdir -p /var/lib/libvirt/vgabios
            ln -sf ${qemu}/bin/qemu /var/lib/libvirt/hooks/qemu
            ${lib.getExe qemu-mkdisk-win}
            ${lib.getExe qemu-mkdisk-nixos}
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
        trustedInterfaces = ["virbr0"];
      };
    };

    environment = {
      systemPackages =
        (with pkgs; [
          tigervnc
          virt-manager
          virt-viewer
          spice
          spice-gtk
          spice-protocol
          libguestfs
          virtio-win
          win-spice
          looking-glass-client
          scream
        ])
        ++ [iommu-check qemu];
      etc = {
        "modules-load.d/kvmfr.conf".text = ''
          kvmfr
        '';
        "modprobe.d/kvmfr.conf".text = ''
          options kvmfr static_size_mb=256
        '';
      };
    };

    services.udev.packages = [
      (
        pkgs.writeTextFile
        {
          name = "kvmfr";
          text = ''
            SUBSYSTEM=="kvmfr", GROUP="kvm", MODE="0660", TAG+="uaccess"
          '';
          destination = "/etc/udev/rules.d/70-kvmfr.rules";
        }
      )
      (
        pkgs.writeTextFile
        {
          name = "vfio";
          text = ''
            SUBSYSTEM=="vfio", GROUP="kvm", MODE="0660", TAG+="uaccess"
          '';
          destination = "/etc/udev/rules.d/70-vfio.rules";
        }
      )
    ];

    virtualisation = {
      libvirtd = {
        onBoot = "ignore";
        onShutdown = "shutdown";
        allowedBridges = ["virbr0"];
        qemu = {
          runAsRoot = true;
          verbatimConfig = ''
            namespaces = []
            cgroup_device_acl = [
              "/dev/null", "/dev/full", "/dev/zero",
              "/dev/random", "/dev/urandom",
              "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
              "/dev/rtc","/dev/hpet", "/dev/vfio/vfio",
              "/dev/kvmfr0"
            ]
          '';
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

        connections = let
          networks = [
            {
              definition = inputs.nixvirt.lib.network.writeXML {
                name = "default";
                uuid = "fd64df3b-30ed-495c-ba06-b2f292c10d92";
                forward.mode = "nat";
                forward.nat.port = {
                  start = 1024;
                  end = 65535;
                };
                bridge = {
                  name = "virbr0";
                  stp = true;
                  delay = 0;
                };
                ip = {
                  address = "192.168.122.1";
                  netmask = "255.255.255.0";
                  dhcp.range = {
                    start = "192.168.122.2";
                    end = "192.168.122.254";
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
        in {
          "qemu:///system" = {
            inherit networks pools;
          };
          "qemu:///session" = {
            inherit networks pools;
          };
        };
      };
    };

    programs = {
      virt-manager = {
        inherit (cfg.virt-manager) enable;
      };
    };

    home-manager = lib.mkIf (config.modules.home-manager.enable) {
      users = {
        ${user} = {
          wayland = {
            windowManager = {
              hyprland = {
                extraConfig = ''
                  windowrule = fullscreen on, match:class (looking-glass-client)
                '';
              };
            };
          };
        };
      };
    };
  };
}
