{config, ...}: {
  home-manager = {
    users = {
      ${config.modules.users.user} = {
        modules = {
          enable = false;
          airgap = {
            enable = false;
          };
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
          development = {
            enable = false;
            cargo = {
              enable = false;
            };
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
            tongo = {
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
                hyprpicker = {
                  enable = false;
                };
                hyprshade = {
                  enable = false;
                };
                hyprsunset = {
                  enable = false;
                };
                xwayland = {
                  enable = false;
                };
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
              defaultLauncher = "rofi";
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
              teams = {
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
            rss = {
              enable = false;
              newsboat = {
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
              enableDebianKeyring = false;
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
            gparted = {
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
  };
}
