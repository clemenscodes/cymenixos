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
    home-manager = {
      users = {
        ${config.modules.users.name} = {
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
              overrideConfig = false;
              resetFiles = [];
              resetFilesExclude = [];
              startup = {
                dataDir = "data";
                desktopScript = {};
                startupScript = {};
              };
              window-rules = {};
              windows = {
                allowWindowsToRememberPositions = true;
              };
              workspace = {
                clickItemTo = "open";
                colorScheme = "BreezeDark";
                enableMiddleClickPaste = true;
                cursor = {};
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
              panels = {};
              powerdevil = {};
              file = {};
              configFile = {};
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
                lockOnStartup = true;
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
                  location = {};
                  mode = "location";
                  temperature = {
                    day = 4500;
                    night = 6500;
                  };
                };
                tiling = {
                  layout = {};
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
                  magnifier = {
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
                  wobblyWindows = {
                    enable = true;
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
                  pointSize = 16;
                };
                menu = {
                  family = "Iosevka";
                  pointSize = 16;
                };
                small = {
                  family = "Iosevka";
                  pointSize = 12;
                };
                fixedWidth = {
                  family = "Iosevka";
                  pointSize = 16;
                };
                toolbar = {
                  family = "Iosevka";
                  pointSize = 16;
                };
                windowTitle = {
                  family = "Iosevka";
                  pointSize = 16;
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
