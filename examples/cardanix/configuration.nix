{
  inputs,
  config,
  system,
  ...
}: {
  imports = [inputs.cymenixos.nixosModules.${system}.default];
  modules = {
    enable = true;
    disk = {
      enable = true;
      device = "/dev/sda";
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
    };
    boot = {
      enable = false;
      efiSupport = false;
      device = "nodev";
      secureboot = {
        enable = true;
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
      users = {
        ${config.modules.users.user} = {
          modules = {
            browser = {
              enable = false;
              defaultBrowser = "brave";
              chromium = {
                enable = false;
              };
              firefox = {
                enable = false;
              };
            };
          };
          development = {
            enable = false;
            direnv = {
              enable = false;
            };
            gh = {
              enable = false;
              plugins = {
                enable = false;
                gh-dash = {
                  enable = false;
                };
              };
            };
            git = {
              enable = false;
              userName = null; # Must be set when git is enabled
              userEmail = null; # Must be set when git is enabled
            };
            pentesting = {
              enable = false;
              burpsuite = {
                enable = false;
              };
            };
            postman = {
              enable = false;
            };
            reversing = {
              enable = false;
              ghidra = {
                enable = false;
              };
              ida = {
                enable = false;
              };
              imhex = {
                enable = false;
              };
            };
          };
          display = {
            enable = false;
            bar = {
              enable = false;
              waybar = {
                enable = false;
              };
            };
            compositor = {
              enable = false;
              hyprland = {
                enable = false;
              };
            };
            cursor = {
              enable = false;
            };
            gtk = {
              enable = false;
            };
            imageviewer = {
              enable = false;
              defaultImageViewer = "swayimg";
              swayimg = {
                enable = false;
              };
            };
            launcher = {
              enable = false;
              rofi = {
                enable = false;
              };
            };
            lockscreen = {
              enable = false;
              defaultLockScreen = "hyprlock";
              hyprlock = {
                enable = false;
              };
              sway-audio-idle-inhibit = {
                enable = false;
              };
              swayidle = {
                enable = false;
              };
              swaylock = {
                enable = false;
              };
            };
            notifications = {
              enable = false;
              defaultNotificationCenter = "swaync";
              swaync = {
                enable = false;
              };
            };
            pdfviewer = {
              enable = false;
              defaultPdfViewer = "zathura";
              calibre = {
                enable = false;
              };
              zathura = {
                enable = false;
              };
            };
            qt = {
              enable = false;
            };
            screenshots = {
              enable = false;
            };
            vnc = {
              enable = false;
              defaultVNC = "wayvnc";
              wayvnc = {
                enable = false;
              };
              tigervnc = {
                enable = false;
              };
            };
          };
          editor = {
            enable = false;
            defaultEditor = "nvim";
            jetbrains = {
              enable = false;
              clion = {
                enable = false;
              };
              pycharm = {
                enable = false;
              };
            };
            nvim = {
              enable = false;
            };
            vscode = {
              enable = false;
              proprietary = false;
            };
            zed = {
              enable = false;
            };
          };
          explorer = {
            enable = false;
            defaultExplorer = "yazi";
            dolphin = {
              enable = false;
            };
            lf = {
              enable = false;
            };
            yazi = {
              enable = false;
            };
          };
          fonts = {
            enable = false;
          };
          media = {
            enable = false;
            audio = {
              enable = false;
              audacity = {
                enable = false;
              };
              interfaces = {
                enable = false;
                scarlett = {
                  enable = false;
                  alsa-scarlett-gui = {
                    enable = false;
                  };
                  scarlett2 = {
                    enable = false;
                  };
                };
              };
            };
            communication = {
              enable = false;
              discord = {
                enable = false;
              };
              element = {
                enable = false;
              };
            };
            editing = {
              enable = false;
              backgroundremover = {
                enable = false;
              };
              davinci = {
                enable = false;
              };
              gimp = {
                enable = false;
              };
              gstreamer = {
                enable = false;
              };
              handbrake = {
                enable = false;
              };
              inkscape = {
                enable = false;
              };
              kdenlive = {
                enable = false;
              };
            };
            games = {
              enable = false;
              stockfish = {
                enable = false;
              };
            };
            music = {
              enable = false;
              dlplaylist = {
                enable = false;
              };
              ncmpcpp = {
                enable = false;
              };
              spotdl = {
                enable = false;
              };
              spotify = {
                enable = false;
              };
            };
            video = {
              enable = false;
              mpris = {
                enable = false;
              };
              mpv = {
                enable = false;
              };
              obs = {
                enable = false;
              };
              vhs = {
                enable = false;
              };
            };
          };
          monitoring = {
            enable = false;
            btop = {
              enable = false;
            };
            ncdu = {
              enable = false;
            };
          };
          networking = {
            enable = false;
            bluetooth = {
              enable = false;
              blueman = {
                enable = false;
              };
            };
            irc = {
              enable = false;
              irssi = {
                enable = false;
              };
              pidgin = {
                enable = false;
              };
            };
            nm = {
              enable = false;
            };
            proxy = {
              enable = false;
              charles = {
                enable = false;
              };
              mitmproxy = {
                enable = false;
              };
            };
            wireshark = {
              enable = false;
            };
          };
          operations = {
            enable = false;
            vps = {
              enable = false;
              hcloud = {
                enable = false;
              };
            };
          };
          organization = {
            enable = false;
            calcurse = {
              enable = false;
            };
            email = {
              enable = false;
              accounts = [
                {
                  address = null;
                  primary = null;
                  realName = null;
                  userName = null;
                  smtpHost = null;
                  smtpPort = null;
                  imapHost = null;
                  imapPort = null;
                  secretName = null;
                }
              ];
            };
            libreoffice = {
              enable = false;
            };
            zotero = {
              enable = false;
            };
          };
          security = {
            enable = false;
            bitwarden = {
              enable = false;
            };
            gpg = {
              enable = false;
            };
            sops = {
              enable = false;
            };
            ssh = {
              enable = false;
            };
          };
          shell = {
            enable = false;
            multiplexers = {
              enable = false;
              tmux = {
                enable = false;
              };
              zellij = {
                enable = false;
              };
            };
            nom = {
              enable = false;
            };
            nvd = {
              enable = false;
            };
            starship = {
              enable = false;
            };
            zoxide = {
              enable = false;
            };
            zsh = {
              enable = false;
            };
          };
          storage = {
            enable = false;
            rclone = {
              enable = false;
              gdrive = {
                enable = false;
                mount = "gdrive";
                crypt = null; # "${cfg.rclone.gdrive.mount}_crypt";
                config = null; #"${cfg.rclone.gdrive.mount}.conf";
                storage = null; #"$HOME/.local/share/storage/${cfg.rclone.gdrive.mount}";
                sync = null; #"$HOME/.local/share/sync/${cfg.rclone.gdrive.mount}";
                clientId = null;
                clientSecret = null;
                token = null;
                encryption_password = null;
                encryption_salt = null;
              };
            };
          };
          terminal = {
            enable = false;
            defaultTerminal = "kitty";
            ghostty = {
              enable = false;
            };
            kitty = {
              enable = false;
            };
          };
          utils = {
            enable = false;
            bat = {
              enable = false;
            };
            fzf = {
              enable = false;
            };
            lpi = {
              enable = false;
            };
            lsusb = {
              enable = false;
            };
            nix-prefetch-git = {
              enable = false;
            };
            nix-prefetch-github = {
              enable = false;
            };
            ripgrep = {
              enable = false;
            };
            tldr = {
              enable = false;
            };
            unzip = {
              enable = false;
            };
            zip = {
              enable = false;
            };
          };
          xdg = {
            enable = false;
          };
        };
      };
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
      fuse = {
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
        enable = true;
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
