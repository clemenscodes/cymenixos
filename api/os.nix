{...}: {
  modules = {
    enable = true;
    airgap = {
      enable = false;
      offline = false;
    };
    disk = {
      enable = true;
      device = "/dev/sda";
      luksDisk = "luks";
      swapsize = 16;
      luks = {
        slot = 2;
        keySize = 512;
        saltLength = 16;
        iterations = 1000000;
        cipher = "aes-xts-plain64";
        hash = "sha512";
        keyFile = "/tmp/luks.key";
      };
    };
    config = {
      enable = true;
      nix = {
        enable = true;
      };
    };
    users = {
      enable = true;
      user = "nixos";
      name = "nixos";
      wheel = false;
      uid = 1000;
      flake = ".local/src/cymenixos";
      initialHashedPassword = "";
    };
    boot = {
      enable = false;
      biosSupport = false;
      efiSupport = false;
      libreboot = false;
      device = "nodev";
      hibernation = false;
      swapResumeOffset = 533760;
      secureboot = {
        enable = false;
      };
      cachyos = {
        enable = false;
        variant = "linuxPackages-cachyos-latest";
      };
    };
    cpu = {
      enable = false;
      vendor = "intel";
      amd = {
        enable = false;
      };
      intel = {
        enable = false;
      };
      msr = {
        enable = false;
      };
    };
    display = {
      enable = false;
      gui = "wayland"; # or "headless"
      gtk = {
        enable = false;
      };
      hyprland = {
        enable = false;
      };
      plasma = {
        enable = false;
      };
      qt = {
        enable = false;
      };
      sddm = {
        enable = false;
      };
    };
    docs = {
      enable = false;
    };
    fonts = {
      enable = false;
      defaultFont = "VictorMono Nerd Font";
      size = 8;
    };
    gaming = {
      enable = false;
      emulation = {
        enable = false;
        pcsx2 = {
          enable = false;
        };
        rpcs3 = {
          enable = false;
        };
      };
      gamemode = {
        enable = false;
      };
      gamescope = {
        enable = false;
      };
      heroic = {
        enable = false;
      };
      lutris = {
        enable = false;
      };
      mangohud = {
        enable = false;
      };
      nexusmods = {
        enable = false;
      };
      steam = {
        enable = false;
      };
      umu = {
        enable = false;
      };
      w3champions = {
        enable = false;
      };
    };
    gpu = {
      enable = false;
      vendor = "amd";
      amd = {
        enable = false;
        corectrl = {
          enable = false;
        };
        lact = {
          enable = false;
        };
      };
      nvidia = {
        enable = false;
      };
    };
    home-manager = {
      enable = false;
    };
    hostname = {
      enable = false;
      defaultHostname = "cymenix";
    };
    io = {
      enable = false;
      android = {
        enable = false;
      };
      input-remapper = {
        enable = false;
      };
      printing = {
        enable = false;
      };
      sound = {
        enable = false;
      };
      udisks = {
        enable = false;
      };
      xremap = {
        enable = false;
      };
      ydotool = {
        enable = false;
      };
    };
    locale = {
      enable = false;
      defaultLocale = "de";
    };
    machine = {
      kind = "desktop";
      name = "desktop";
    };
    networking = {
      enable = false;
      bluetooth = {
        enable = false;
      };
      dbus = {
        enable = false;
      };
      firewall = {
        enable = false;
      };
      irc = {
        enable = false;
        weechat = {
          enable = false;
        };
      };
      mtr = {
        enable = false;
      };
      stevenblack = {
        enable = false;
      };
      torrent = {
        enable = false;
        mullvadAccountSecretPath = null;
        mullvadDns = false;
      };
      upnp = {
        enable = false;
      };
      vpn = {
        enable = false;
        thm = {
          enable = false;
          usernameFile = null;
          passwordFile = null;
        };
      };
      wireless = {
        enable = false;
        eduroam = {
          enable = false;
        };
      };
      wireshark = {
        enable = false;
      };
    };
    performance = {
      enable = false;
      auto-cpufreq = {
        enable = false;
      };
      power = {
        enable = false;
      };
      thermald = {
        enable = false;
      };
      tlp = {
        enable = false;
      };
    };
    security = {
      enable = false;
      diceware = {
        enable = true;
        addr = "localhost";
        port = 8080;
      };
      gnome-keyring = {
        enable = false;
      };
      gnupg = {
        enable = false;
      };
      hyprlock = {
        enable = false;
      };
      polkit = {
        enable = false;
      };
      rtkit = {
        enable = false;
      };
      sops = {
        enable = false;
      };
      ssh = {
        enable = false;
      };
      sudo = {
        enable = false;
        noPassword = false;
      };
      swaylock = {
        enable = false;
      };
      tpm = {
        enable = false;
      };
      yubikey = {
        enable = false;
        pam = {
          enable = false;
          u2f-mappings = [];
          identifiers = [];
        };
      };
    };
    shell = {
      enable = false;
      console = {
        enable = false;
      };
      environment = {
        enable = false;
      };
      ld = {
        enable = false;
      };
      zsh = {
        enable = false;
      };
    };
    themes = {
      enable = false;
      base = {
        enable = false;
      };
      catppuccin = {
        enable = false;
        flavor = "macchiato";
        accent = "blue";
      };
    };
    time = {
      enable = false;
      defaultTimeZone = "Europe/Berlin";
    };
    virtualisation = {
      enable = false;
      docker = {
        enable = false;
      };
      podman = {
        enable = false;
      };
      virt-manager = {
        enable = false;
      };
    };
    wsl = {
      enable = false;
    };
    xdg = {
      enable = false;
    };
  };
}
