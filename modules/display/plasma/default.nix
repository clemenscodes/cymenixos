{
  inputs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.display;
  inherit (config.modules.boot.impermanence) persistPath;
  inherit (config.modules.users) name;
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [
      (final: prev: {
        kdePackages = prev.kdePackages.overrideScope (kdeFinal: kdePrev: {
          powerdevil = kdePrev.powerdevil.overrideAttrs (oldAttrs: {
            patches = oldAttrs.patches or [];
          });
        });
      })
    ];
  };
in {
  options = {
    modules = {
      display = {
        plasma = {
          enable = lib.mkEnableOption "Enable plasma" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.plasma.enable) {
    environment = {
      persistence = lib.mkIf (config.modules.boot.enable) {
        ${persistPath} = {
          users = {
            ${name} = {
              files = [
                ".config/baloofilerc"
                ".config/gtkrc"
                ".config/gtkrc-2.0"
                ".config/kactivitymanagerd-statsrc"
                ".config/kactivitymanagerdrc"
                ".config/kconf_updaterc"
                ".config/kded5rc"
                ".config/kdeglobals"
                ".config/kdeglobalshortcutsrc"
                ".config/ktimezonedrc"
                ".config/kwinoutputconfig.json"
                ".config/kwinrc"
                ".config/plasma-localerc"
                ".config/plasma-org.kde.plasma.desktop-appletsrc"
                ".config/plasmashellrc"
                ".config/powermanagementprofilesrc"
                ".config/Trolltech"
              ];
            };
          };
        };
      };
    };
    home-manager = {
      users = {
        ${name} = {
          imports = [inputs.plasma-manager.homeModules.plasma-manager];
          programs = {
            elisa = {
              enable = false;
            };
            kate = {
              enable = false;
            };
            ghostwriter = {
              enable = false;
            };
            konsole = {
              enable = false;
            };
            okular = {
              enable = false;
            };
            plasma = {
              inherit (cfg.plasma) enable;
              overrideConfig = true;
              resetFiles = [];
              resetFilesExclude = [];
              startup = {
                dataDir = "data";
                desktopScript = {};
                startupScript = {};
              };
              window-rules = [];
              windows = {
                allowWindowsToRememberPositions = true;
              };
              workspace = {
                clickItemTo = "open";
                colorScheme = "BreezeDark";
                enableMiddleClickPaste = true;
                cursor = {};
                soundTheme = "freedesktop";
                iconTheme = "Papirus-Dark";
                lookAndFeel = "org.kde.breezedark.desktop";
                theme = "breeze-dark";
                widgetStyle = "breeze";
              };
              session = {
                general = {
                  askForConfirmationOnLogout = true;
                };
                sessionRestore = {
                  excludeApplications = ["firefox" "brave" "kitty"];
                  restoreOpenApplicationsOnLogin = "startWithEmptySession";
                };
              };
              shortcuts = {};
              panels = [];
              powerdevil = {};
              file = {};
              configFile = {
                kdeglobals = {
                  General = {
                    TerminalApplication = "kitty";
                    TerminalService = "kitty.desktop";
                  };
                };
              };
              dataFile = {};
              desktop = {
                icons = {};
                mouseActions = {};
                widgets = [];
              };
              hotkeys = {
                commands = {};
              };
              input = {
                keyboard = {
                  layouts = [{layout = "de";}];
                  options = [
                    "ctrl:nocaps"
                  ];
                  repeatDelay = 300;
                  repeatRate = 50;
                };
                mice = [];
                touchpads = [];
              };
              krunner = {
                activateWhenTypingOnDesktop = true;
                historyBehavior = "enableAutoComplete";
                position = "center";
                shortcuts = {
                  launch = null;
                  runCommandOnClipboard = null;
                };
              };
              kscreenlocker = {
                appearance = {
                  showMediaControls = true;
                };
                autoLock = true;
                lockOnResume = true;
                lockOnStartup = false;
                passwordRequired = true;
                passwordRequiredDelay = 10;
                timeout = 15;
              };
              kwin = {
                borderlessMaximizedWindows = true;
                cornerBarrier = true;
                edgeBarrier = 0;
                nightLight = {
                  enable = false;
                  mode = "times";
                  temperature = {
                    day = 4500;
                    night = 6500;
                  };
                  time = {
                    morning = "06:00";
                    evening = "18:00";
                  };
                };
                virtualDesktops = {
                  number = 10;
                  names = ["1" "2" "3" "4" "5" "6" "7" "8" "9" "0"];
                };
                effects = {
                  blur = {
                    enable = true;
                    noiseStrength = 8;
                    strength = 6;
                  };
                  cube = {
                    enable = true;
                  };
                  desktopSwitching = {
                    animation = "fade";
                    navigationWrapping = true;
                  };
                  dimAdminMode = {
                    enable = true;
                  };
                  dimInactive = {
                    enable = true;
                  };
                  fallApart = {
                    enable = false;
                  };
                  fps = {
                    enable = false;
                  };
                  hideCursor = {
                    enable = true;
                    hideOnInactivity = 0;
                    hideOnTyping = false;
                  };
                  invert = {
                    enable = true;
                  };
                  minimization = {
                    animation = "magiclamp";
                  };
                  shakeCursor = {
                    enable = true;
                  };
                  slideBack = {
                    enable = true;
                  };
                  snapHelper = {
                    enable = true;
                  };
                  translucency = {
                    enable = true;
                  };
                  windowOpenClose = {
                    animation = "glide";
                  };
                  zoom = {
                    enable = true;
                    focusTracking = {
                      enable = true;
                    };
                    mousePointer = "keep";
                    mouseTracking = "proportional";
                  };
                };
              };
              fonts = {
                general = {
                  family = "Iosevka";
                  pointSize = 10;
                };
                menu = {
                  family = "Iosevka";
                  pointSize = 10;
                };
                small = {
                  family = "Iosevka";
                  pointSize = 8;
                };
                fixedWidth = {
                  family = "Iosevka";
                  pointSize = 10;
                };
                toolbar = {
                  family = "Iosevka";
                  pointSize = 10;
                };
                windowTitle = {
                  family = "Iosevka";
                  pointSize = 10;
                };
              };
            };
          };
        };
      };
    };
    environment = {
      plasma6 = {
        excludePackages = with pkgs.kdePackages; [
          plasma-browser-integration
          konsole
          elisa
          ghostwriter
          okular
          kate
        ];
      };
    };
    services = {
      displayManager = {
        defaultSession = "plasma";
        sddm = {
          enable = true;
          wayland = {
            enable = true;
          };
          settings = {
            General = {
              DisplayServer = "wayland";
            };
          };
        };
      };
      desktopManager = {
        plasma6 = {
          enable = true;
          enableQt5Integration = true;
        };
      };
    };
  };
}
