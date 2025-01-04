({
  inputs,
  config,
  system,
  ...
}: {
  imports = [inputs.cymenixos.nixosModules.${system}.default];
  modules = {
    enable = true;
    machine = {
      kind = "desktop";
    };
    display = {
      enable = true;
      gui = "headless";
    };
    disk = {
      enable = true;
      device = "/dev/vda";
    };
    boot = {
      enable = true;
      efiSupport = true;
      inherit (config.modules.disk) device;
    };
    hostname = {
      enable = true;
      defaultHostname = "cymenix";
    };
    time = {
      enable = true;
      defaultTimeZone = "Europe/Berlin";
    };
    locale = {
      enable = true;
      defaultLocale = "de";
    };
    themes = {
      enable = true;
      catppuccin = {
        enable = true;
        flavor = "macchiato";
        accent = "blue";
      };
    };
    users = {
      enable = true;
      wheel = true;
      user = "nixos";
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
    xdg = {
      enable = true;
    };
    io = {
      enable = true;
      sound = {
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
    };
    security = {
      enable = true;
      gnome-keyring = {
        enable = true;
      };
      gnupg = {
        enable = true;
      };
    };
    config = {
      enable = true;
      nix = {
        enable = true;
      };
    };
  };
})
