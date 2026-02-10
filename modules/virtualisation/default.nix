{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
  user = cfg.users.user;
  isDesktop = cfg.display.gui != "headless";
in {
  imports = [
    (import ./docker {inherit inputs pkgs lib;})
    (import ./podman {inherit inputs pkgs lib;})
    (import ./virt-manager {inherit inputs pkgs lib;})
    (import ./waydroid {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      virtualisation = {
        enable = lib.mkEnableOption "Enable virtualisation" // {default = false;};
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.virtualisation.enable) {
    environment = {
      persistence = {
        ${config.modules.boot.impermanence.persistPath} = {
          directories = ["/var/lib/libvirt"];
        };
      };
    };
    virtualisation = {
      libvirtd = {
        inherit (cfg.virtualisation) enable;
        qemu = {
          package = pkgs.qemu_kvm;
          vhostUserPackages = [pkgs.virtiofsd];
          swtpm = {
            inherit (cfg.virtualisation) enable;
          };
        };
      };
      spiceUSBRedirection = {
        inherit (cfg.virtualisation) enable;
      };
    };
    services = {
      spice-vdagentd = {
        inherit (cfg.virtualisation) enable;
      };
      spice-webdavd = {
        inherit (cfg.virtualisation) enable;
      };
      qemuGuest = {
        inherit (cfg.virtualisation) enable;
      };
    };
    users = {
      users = {
        ${config.modules.users.name} = {
          extraGroups = ["usb"];
        };
      };
    };
    security = {
      polkit = {
        extraConfig =
          /*
          javascript
          */
          ''
            polkit.addRule(function(action, subject) {
              if (action.id == "org.libvirt.unix.manage" && subject.isInGroup("wheel")) {
                return polkit.Result.YES;
              }
            });
          '';
      };
    };
    home-manager = lib.mkIf (cfg.home-manager.enable && isDesktop) {
      users = {
        ${user} = {
          dconf = {
            settings = {
              "org/virt-manager/virt-manager/connections" = {
                autoconnect = ["qemu:///system"];
                uris = ["qemu:///system"];
              };
            };
          };
        };
      };
    };
  };
}
