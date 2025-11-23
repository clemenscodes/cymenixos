{
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
      name = "desktop";
    };
    hostname = {
      enable = true;
      defaultHostname = "cymenix";
    };
    users = {
      enable = true;
      wheel = true;
      user = "nixos";
      initialHashedPassword = "";
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
      defaultFont = "VictorMono Nerd Font";
      size = 8;
    };
    config = {
      enable = true;
      nix = {
        enable = true;
      };
    };
    disk = {
      enable = true;
      device = "/dev/sda";
      luksDisk = "luks";
      swapsize = 64;
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
      amd = {
        enable = true;
      };
    };
    display = {
      enable = true;
      gui = "wayland";
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
        noPassword = true;
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
          development = {
            enable = true;
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
              userEmail = "me@clemenshorn.com";
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
          media = {
            enable = true;
            audio = {
              enable = true;
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
            music = {
              enable = true;
              ncmpcpp = {
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
