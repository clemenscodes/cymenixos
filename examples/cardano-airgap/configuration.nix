{
  inputs,
  config,
  system,
  ...
}: {
  imports = [inputs.cymenixos.nixosModules.${system}.default];
  modules = {
    enable = true;
    airgap = {
      enable = true;
      cardano = {
        enable = false;
      };
    };
    disk = {
      enable = true;
      device = "/dev/sda";
      luksDisk = "luks";
      swapsize = 64;
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
    machine = {
      kind = "desktop";
      name = "desktop";
    };
    config = {
      enable = false;
      nix = {
        enable = true;
      };
    };
    users = {
      enable = true;
      wheel = true;
      user = "airgap";
      initialHashedPassword = "";
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
    locale = {
      enable = true;
      defaultLocale = "de";
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
    themes = {
      enable = true;
      catppuccin = {
        enable = true;
        flavor = "macchiato";
        accent = "blue";
      };
    };
    time = {
      enable = true;
      defaultTimeZone = "Europe/Berlin";
    };
    xdg = {
      enable = true;
    };
  };
  home-manager = {
    users = {
      ${config.modules.users.user} = {
        modules = {
          enable = true;
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
            video = {
              enable = true;
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
          security = {
            enable = true;
            gpg = {
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
            gparted = {
              enable = true;
            };
            ripgrep = {
              enable = true;
            };
            unzip = {
              enable = true;
            };
            lsusb = {
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
