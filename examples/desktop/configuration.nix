{
  inputs,
  pkgs,
  config,
  system,
  lib,
  ...
}: {
  imports = [inputs.cymenixos.nixosModules.${system}.default];
  modules = {
    enable = true;
    disk = {
      enable = true;
      device = "/dev/vdb";
      swapsize = 64;
    };
    machine = {
      kind = "desktop";
      name = "desktop";
    };
    config = {
      enable = true;
      nix = {
        enable = true;
      };
    };
    nyx = {
      enable = true;
    };
    users = {
      enable = true;
      wheel = true;
      user = "clemens";
    };
    boot = {
      enable = true;
      biosSupport = true;
      efiSupport = true;
      libreboot = false;
      inherit (config.modules.disk) device;
      hibernation = true;
      swapResumeOffset = 533760;
    };
    cpu = {
      enable = true;
      vendor = "intel";
      intel = {
        enable = true;
      };
      msr = {
        enable = true;
      };
    };
    gpu = {
      enable = true;
      amd = {
        enable = true;
      };
    };
    databases = {
      enable = true;
      mongodb = {
        enable = false;
      };
    };
    crypto = {
      enable = true;
      ledger-live = {
        enable = true;
      };
    };
    display = {
      enable = true;
      gui = "wayland"; # or "headless"
      gtk = {
        enable = true;
      };
      hyprland = {
        enable = true;
      };
      plasma = {
        enable = false;
      };
      qt = {
        enable = true;
      };
      sddm = {
        enable = true;
      };
    };
    fonts = {
      enable = true;
      defaultFont = "VictorMono Nerd Font";
      size = 8;
    };
    home-manager = {
      enable = true;
    };
    hostname = {
      enable = true;
      defaultHostname = "cymenix";
    };
    io = {
      enable = true;
      printing = {
        enable = false;
      };
      input-remapper = {
        enable = true;
      };
      sound = {
        enable = true;
      };
      udisks = {
        enable = true;
      };
      xremap = {
        enable = true;
      };
      ydotool = {
        enable = true;
      };
    };
    locale = {
      enable = true;
      defaultLocale = "de";
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
        enable = false;
      };
      stevenblack = {
        enable = true;
      };
      wireless = {
        enable = true;
      };
    };
    security = {
      enable = true;
      diceware = {
        enable = true;
      };
      gnome-keyring = {
        enable = true;
      };
      gnupg = {
        enable = true;
      };
      hyprlock = {
        enable = true;
      };
      polkit = {
        enable = true;
      };
      rtkit = {
        enable = true;
      };
      ssh = {
        enable = true;
      };
      sudo = {
        enable = true;
        noPassword = false;
      };
      tpm = {
        enable = true;
      };
      yubikey = {
        enable = true;
        pam = {
          enable = true;
          identifiers = {
            sequwitie = 31631244;
            matcha = 31861924;
          };
          token-ids = [
            "vvcccbudlijr" # sequwitie
            "vvcccbuhdrlf" # matcha
          ];
          u2f-mappings = [
            "BIy34cqfJbjqbGflC1sK064geZZm9ma8PEcv+lNyBcy9PPQuJx1jlYTfx6wBdtyST4a493/hy/bCvjtygHM8cg==,zvs4JcxffM814ItVLiVmNoMAL7rf1W/ZxLFbA9xkf1CEWiHI7LGdQVIp4NiOzTHMZFUobJwN4emnmGcrR3zKGg==,es256,+presence" # sequwitie
            "PvMKJy6Uqzqkb+YXyRhOnLn3rj+d1unpIZ3hnXE0rwfCnKePv5qfa8QFFq7sFIioq8lKvtN2kdYDLvC7+FRiFg==,iDqLO5PXwW3frmeWeZwyzCjLnTey+dC7DIz6OfCsMgNC1sAkiEnbnR1EK+Dt0V7frD5h3iopxrf6QdC8Tg37cg==,es256,+presence"
          ];
        };
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
    virtualisation = {
      enable = true;
      docker = {
        enable = false;
      };
      virt-manager = {
        enable = true;
        windows = {
          enable = true;
        };
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
    performance = {
      enable = true;
    };
    time = {
      enable = true;
      defaultTimeZone = "Europe/Berlin";
    };
    xdg = {
      enable = true;
    };
    gaming = {
      enable = true;
      steam = {
        enable = true;
      };
      gamescope = {
        enable = true;
      };
      gamemode = {
        enable = true;
      };
      mangohud = {
        enable = true;
      };
      nexusmods = {
        enable = false;
      };
      lutris = {
        enable = true;
      };
      umu = {
        enable = true;
      };
      w3champions = {
        enable = true;
        flo = {
          enable = true;
        };
      };
    };
  };
  home-manager = {
    users = {
      ${config.modules.users.user} = {
        modules = {
          enable = true;
          browser = {
            enable = true;
            defaultBrowser = "brave";
            firefox = {
              enable = true;
            };
            chromium = {
              enable = true;
            };
          };
          development = {
            enable = true;
            cargo = {
              enable = true;
            };
            direnv = {
              enable = true;
            };
            gh = {
              enable = true;
              plugins = {
                enable = true;
                gh-dash = {
                  enable = true;
                };
              };
            };
            git = {
              enable = true;
              userName = "Clemens Horn";
              userEmail = "clemens.horn@mni.thm.de";
              signing = {
                enable = true;
                gpgFingerprint = "52E30A92E24B09D5";
              };
            };
            tongo = {
              enable = true;
            };
          };
          display = {
            enable = true;
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
            launcher = {
              enable = true;
              defaultLauncher = "rofi";
              rofi = {
                enable = true;
              };
            };
            lockscreen = {
              enable = true;
              defaultLockScreen = "hyprlock";
              hyprlock = {
                enable = true;
              };
            };
            notifications = {
              enable = true;
              defaultNotificationCenter = "swaync";
              swaync = {
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
          media = {
            enable = true;
            audio = {
              enable = true;
              audacity = {
                enable = true;
              };
              interfaces = {
                enable = true;
                scarlett = {
                  enable = true;
                  alsa-scarlett-gui = {
                    enable = true;
                  };
                  scarlett2 = {
                    enable = true;
                  };
                };
              };
            };
            rss = {
              enable = true;
              newsboat = {
                enable = true;
              };
            };
            communication = {
              enable = true;
              discord = {
                enable = true;
              };
              element = {
                enable = true;
              };
            };
            music = {
              enable = true;
              dlplaylist = {
                enable = true;
              };
              ncmpcpp = {
                enable = true;
              };
            };
            editing = {
              enable = true;
              davinci = {
                enable = false;
              };
              gstreamer = {
                enable = true;
              };
            };
            video = {
              enable = true;
              mpris = {
                enable = true;
              };
              mpv = {
                enable = true;
              };
              obs = {
                enable = true;
              };
            };
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
          organization = {
            enable = true;
            libreoffice = {
              enable = true;
            };
            zotero = {
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
            bitwarden = {
              enable = true;
            };
            gpg = {
              enable = true;
            };
            ssh = {
              enable = true;
            };
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
            ghostty = {
              enable = true;
            };
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
            lpi = {
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
}
