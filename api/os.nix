{...}: {
  modules = {
    enable = true;
    airgap = {
      enable = false;
      offline = false;
      cardano = {
        enable = false;
      };
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
      cachix = {
        enable = false;
        token = null;
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
    crypto = {
      enable = false;
      cardanix = {
        enable = false;
      };
      ledger-live = {
        enable = false;
      };
      monero = {
        enable = false;
        settings = {
          wallet = "49j7AMxXgkBVioejSyBkxBXQSfDDVB9U71vqimeaLrDRBeaK5jc3NH5RNBHTgKSofeGWuCqRRUZTDbRcctVswNXEKSwszEN";
          host = "127.0.0.1";
          monero = "monero";
          xmrig = "xmrig";
          p2pool = "p2pool";
          p2pPort = 18080;
          p2poolPort = 37889;
          p2poolMiniPort = 37888;
          p2poolStratumPort = 3333;
          p2poolStratumApiPort = 3334;
          zmqPort = 18083;
          rpcPort = 18089;
          rateLimit = 128000;
          loglevel = 3;
        };
      };
      nanominer = {
        enable = false;
        wallet = "9grgD7e5K5ZK5dMtVnAfedVya2kLPpzzygmfYuiCaKvVeDfEz1q";
        pool = "de.ergo.herominers.com:1180";
        rig = "xtx7900";
        coin = "ergo";
        ethmanPort = "3335";
        email = null;
      };
      ravencoin = {
        enable = false;
        pool = "de.ravencoin.herominers.com:1140";
        wallet = "RMpstu9fgiENPCfiZmLnX1MoBhaCabLkxR";
        worker = "xtx7900";
      };
      teamredminer = {
        enable = false;
        wallet = "9grgD7e5K5ZK5dMtVnAfedVya2kLPpzzygmfYuiCaKvVeDfEz1q";
        pool = "de.ergo.herominers.com:1180";
        rig = "xtx7900";
        algorithm = "autolykos2";
      };
    };
    databases = {
      enable = false;
      postgres = {
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
      lutris = {
        enable = false;
      };
      battlenet = {
        enable = false;
      };
      steam = {
        enable = false;
      };
      umu = {
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
