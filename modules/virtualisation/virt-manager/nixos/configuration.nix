{
  inputs,
  config,
  system,
  ...
}: {
  imports = [
    inputs.cymenixos.nixosModules.${system}.default
    inputs.mtkwifi.nixosModules.mt7927
  ];
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
}
