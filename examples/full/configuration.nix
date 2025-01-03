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
    };
    users = {
      enable = true;
      user = "nixos";
    };
    boot = {
      enable = true;
      efiSupport = true;
      inherit (config.modules.disk) device;
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
    gpu = {
      enable = true;
      vendor = "amd";
      amd = {
        enable = true;
      };
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
      fuse = {
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
    };
    locale = {
      enable = true;
      defaultLocale = "de";
    };
    machine = {
      kind = "desktop";
      name = "desktop";
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
      stevenblack = {
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
      sops = {
        enable = false;
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
    virtualisation = {
      enable = true;
      docker = {
        enable = true;
      };
      virt-manager = {
        enable = true;
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
              userName = "Clemens Horn"; # Must be set when git is enabled
              userEmail = "clemens.horn@mni.thm.de"; # Must be set when git is enabled
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
            communication = {
              enable = true;
              discord = {
                enable = true;
              };
              element = {
                enable = true;
              };
            };
            editing = {
              enable = true;
              davinci = {
                enable = true;
              };
              gstreamer = {
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
          organization = {
            enable = true;
            calcurse = {
              enable = true;
            };
            email = {
              enable = false;
              accounts = [];
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
            sops = {
              enable = false;
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
          storage = {
            enable = true;
            rclone = {
              enable = true;
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
            lsusb = {
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