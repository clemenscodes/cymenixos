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
              files = [];
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
              shortcuts = {
                "kitty.desktop"."_launch" = "Meta+Return";
                "brave-browser.desktop"."_launch" = "Meta+W";
                "services/org.kde.konsole.desktop"."_launch" = "None";
                "kwin"."Overview" = "Meta+Tab";
                "kwin"."Show Desktop" = "Meta+D";
                "kwin"."Switch to Desktop 1" = "Meta+1";
                "kwin"."Switch to Desktop 2" = "Meta+2";
                "kwin"."Switch to Desktop 3" = "Meta+3";
                "kwin"."Switch to Desktop 4" = "Meta+4";
                "kwin"."Switch to Desktop 5" = "Meta+5";
                "kwin"."Switch to Desktop 6" = "Meta+6";
                "kwin"."Switch to Desktop 7" = "Meta+7";
                "kwin"."Switch to Desktop 8" = "Meta+8";
                "kwin"."Switch to Desktop 9" = "Meta+9";
                "kwin"."Switch to Desktop 10" = "Meta+0";
                "kwin"."Window Close" = ["Meta+Q"];
                "kwin"."Window Fullscreen" = ["Meta+Shift+F"];
                "kwin"."Window Shrink Horizontal" = [];
                "kwin"."Window Shrink Vertical" = [];
                "kwin"."Window to Desktop 1" = "Meta+!";
                "kwin"."Window to Desktop 2" = "Meta+\"";
                "kwin"."Window to Desktop 3" = "Meta+§";
                "kwin"."Window to Desktop 4" = "Meta+$";
                "kwin"."Window to Desktop 5" = "Meta+%";
                "kwin"."Window to Desktop 6" = "Meta+&";
                "kwin"."Window to Desktop 7" = "Meta+/";
                "kwin"."Window to Desktop 8" = "Meta+(";
                "kwin"."Window to Desktop 9" = "Meta+)";
                "kwin"."Window to Desktop 10" = "Meta+=";
                "plasmashell"."activate task manager entry 1" = [];
                "plasmashell"."activate task manager entry 2" = [];
                "plasmashell"."activate task manager entry 3" = [];
                "plasmashell"."activate task manager entry 4" = [];
                "plasmashell"."activate task manager entry 5" = [];
                "plasmashell"."activate task manager entry 6" = [];
                "plasmashell"."activate task manager entry 7" = [];
                "plasmashell"."activate task manager entry 8" = [];
                "plasmashell"."activate task manager entry 9" = [];
                "plasmashell"."activate task manager entry 10" = [];
                "services/org.kde.dolphin.desktop"."_launch" = "Meta+E";
                "services/org.kde.spectacle.desktop"."ActiveWindowScreenShot" = [];
                "services/org.kde.spectacle.desktop"."FullScreenScreenShot" = "Meta+Shift+S";
                "services/org.kde.spectacle.desktop"."RectangularRegionScreenShot" = "Meta+S";
                "services/org.kde.spectacle.desktop"."WindowUnderCursorScreenShot" = "Meta+Alt+S";
                "services/org.kde.spectacle.desktop"."_launch" = "Print";
              };
              panels = [
                {
                  location = "bottom";
                  floating = true;
                  height = 60;

                  widgets = [
                    {
                      kickoff = {
                        icon = "nix-snowflake";
                      };
                    }

                    {
                      iconTasks = {
                        iconsOnly = true;
                        behavior.grouping.method = "none";
                        launchers = [
                          "applications:kitty.desktop"
                          "preferred://browser"
                        ];
                        settings = {
                          General = {
                            interactiveMute = false;
                          };
                        };
                      };
                    }

                    "org.kde.plasma.marginsseparator"

                    {
                      name = "org.kde.plasma.weather";
                      config = {
                        Appearance.showTemperatureInCompactMode = true;
                        Appearance.showPressureInTooltip = true;
                        WeatherStation.source = "dwd|weather|Eindhoven|06370";
                      };
                    }

                    {
                      digitalClock = {
                        date.enable = false;
                        time.showSeconds = "onlyInTooltip";
                        calendar.showWeekNumbers = true;
                      };
                    }

                    "org.kde.plasma.minimizeall"
                  ];
                }
              ];
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
                borderlessMaximizedWindows = false;
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
                  rows = 1;
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
                  pointSize = 12;
                };
                fixedWidth = {
                  family = "Iosevka";
                  pointSize = 12;
                };
                menu = {
                  family = "Iosevka";
                  pointSize = 10;
                };
                small = {
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
