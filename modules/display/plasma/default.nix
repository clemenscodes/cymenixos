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
              directories = [".local/share/kwalletd"];
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
                kwin = {
                  "Overview" = "Meta+Space";
                  "Show Desktop" = "Meta+Shift+U";
                  "Window Close" = ["Meta+Q"];
                  "Window Fullscreen" = ["Meta+F"];
                  "Window Shrink Horizontal" = [];
                  "Window Shrink Vertical" = [];
                  "Window Quick Tile Bottom" = "Meta+Shift+J";
                  "Window Quick Tile Left" = "Meta+Shift+H";
                  "Window Quick Tile Right" = "Meta+Shift+L";
                  "Window Quick Tile Top" = "Meta+Shift+K";
                  "Window Quick Tile Bottom Left" = [];
                  "Window Quick Tile Bottom Right" = [];
                  "Window Quick Tile Top Left" = [];
                  "Window Quick Tile Top Right" = [];
                  "Switch to Desktop 1" = "Meta+1";
                  "Switch to Desktop 2" = "Meta+2";
                  "Switch to Desktop 3" = "Meta+3";
                  "Switch to Desktop 4" = "Meta+4";
                  "Switch to Desktop 5" = "Meta+5";
                  "Switch to Desktop 6" = "Meta+6";
                  "Switch to Desktop 7" = "Meta+7";
                  "Switch to Desktop 8" = "Meta+8";
                  "Switch to Desktop 9" = "Meta+9";
                  "Switch to Desktop 10" = "Meta+0";
                  "Window to Desktop 1" = "Meta+!";
                  "Window to Desktop 2" = "Meta+\"";
                  "Window to Desktop 3" = "Meta+§";
                  "Window to Desktop 4" = "Meta+$";
                  "Window to Desktop 5" = "Meta+%";
                  "Window to Desktop 6" = "Meta+&";
                  "Window to Desktop 7" = "Meta+/";
                  "Window to Desktop 8" = "Meta+(";
                  "Window to Desktop 9" = "Meta+)";
                  "Window to Desktop 10" = "Meta+=";
                  "Activate Window Demanding Attention" = "Meta+Ctrl+A";
                  "Decrease Opacity" = [];
                  "Edit Tiles" = "Meta+T";
                  "Expose" = "Ctrl+F9";
                  "ExposeAll" = ["Ctrl+F10" "Launch (C)"];
                  "ExposeClass" = "Ctrl+F7";
                  "ExposeClassCurrentDesktop" = [];
                  "Increase Opacity" = [];
                  "MoveMouseToCenter" = "Meta+F6";
                  "MoveMouseToFocus" = "Meta+F5";
                  "MoveZoomDown" = [];
                  "MoveZoomLeft" = [];
                  "MoveZoomRight" = [];
                  "MoveZoomUp" = [];
                  "Setup Window Shortcut" = [];
                  "ShowDesktopGrid" = "Meta+F8";
                  "Suspend Compositing" = "Alt+Shift+F12";
                  "Switch One Desktop Down" = ["Meta+J"];
                  "Switch One Desktop Up" = ["Meta+K"];
                  "Switch One Desktop to the Left" = ["Meta+H"];
                  "Switch One Desktop to the Right" = ["Meta+L"];
                  "Switch Window Down" = "Meta+Alt+Down";
                  "Switch Window Left" = "Meta+Alt+Left";
                  "Switch Window Right" = "Meta+Alt+Right";
                  "Switch Window Up" = "Meta+Alt+Up";
                  "Switch to Next Desktop" = [];
                  "Switch to Next Screen" = [];
                  "Switch to Previous Desktop" = [];
                  "Switch to Previous Screen" = [];
                  "Toggle Night Color" = [];
                  "Toggle Window Raise/Lower" = [];
                  "Walk Through Desktop List" = [];
                  "Walk Through Desktop List (Reverse)" = [];
                  "Walk Through Desktops" = [];
                  "Walk Through Desktops (Reverse)" = [];
                  "Walk Through Windows" = "Alt+Tab";
                  "Walk Through Windows (Reverse)" = "Alt+Shift+Backtab";
                  "Walk Through Windows Alternative" = [];
                  "Walk Through Windows Alternative (Reverse)" = [];
                  "Walk Through Windows of Current Application" = "Alt+`";
                  "Walk Through Windows of Current Application (Reverse)" = "Alt+~";
                  "Walk Through Windows of Current Application Alternative" = [];
                  "Walk Through Windows of Current Application Alternative (Reverse)" = [];
                  "Window Above Other Windows" = [];
                  "Window Below Other Windows" = [];
                  "Window Grow Horizontal" = [];
                  "Window Grow Vertical" = [];
                  "Window Lower" = [];
                  "Window Maximize Horizontal" = [];
                  "Window Maximize Vertical" = [];
                  "Window Move" = [];
                  "Window Move Center" = [];
                  "Window No Border" = [];
                  "Window On All Desktops" = [];
                  "Window One Desktop Down" = "Meta+Ctrl+Shift+Down";
                  "Window One Desktop Up" = "Meta+Ctrl+Shift+Up";
                  "Window One Desktop to the Left" = "Meta+Ctrl+Shift+Left";
                  "Window One Desktop to the Right" = "Meta+Ctrl+Shift+Right";
                  "Window One Screen Down" = [];
                  "Window One Screen Up" = [];
                  "Window One Screen to the Left" = [];
                  "Window One Screen to the Right" = [];
                  "Window Operations Menu" = "Alt+F3";
                  "Window Pack Down" = [];
                  "Window Pack Left" = [];
                  "Window Pack Right" = [];
                  "Window Pack Up" = [];
                  "Window Raise" = [];
                  "Window Resize" = [];
                  "Window Shade" = [];
                  "Window to Next Desktop" = [];
                  "Window to Next Screen" = "Meta+Shift+Right";
                  "Window to Previous Desktop" = [];
                  "Window to Previous Screen" = "Meta+Shift+Left";
                };
                "kitty.desktop"."_launch" = "Meta+Return";
                "brave-browser.desktop"."_launch" = "Meta+W";
                "yazi.desktop"."_launch" = "Meta+E";
                "thunderbird.desktop"."_launch" = "Meta+Shift+E";
                "services/org.kde.konsole.desktop"."_launch" = "None";
                "services/org.kde.spectacle.desktop" = {
                  "ActiveWindowScreenShot" = [];
                  "FullScreenScreenShot" = "Meta+Shift+S";
                  "RectangularRegionScreenShot" = "Meta+S";
                  "WindowUnderCursorScreenShot" = "Meta+Alt+S";
                  "_launch" = "Print";
                };
                plasmashell = {
                  "activate task manager entry 1" = [];
                  "activate task manager entry 2" = [];
                  "activate task manager entry 3" = [];
                  "activate task manager entry 4" = [];
                  "activate task manager entry 5" = [];
                  "activate task manager entry 6" = [];
                  "activate task manager entry 7" = [];
                  "activate task manager entry 8" = [];
                  "activate task manager entry 9" = [];
                  "activate task manager entry 10" = [];
                  "clear-history" = [];
                  "clipboard_action" = "Meta+Ctrl+X";
                  "cycle-panels" = "Meta+Alt+P";
                  "cycleNextAction" = [];
                  "cyclePrevAction" = [];
                  "edit_clipboard" = [];
                  "next activity" = "Meta+Tab";
                  "previous activity" = "Meta+Shift+Tab";
                  "repeat_action" = "Meta+Ctrl+R";
                  "show dashboard" = "Ctrl+F12";
                  "show-barcode" = [];
                  "show-on-mouse-pos" = "Meta+V";
                  "switch to next activity" = [];
                  "switch to previous activity" = [];
                  "toggle do not disturb" = [];
                };
                "KDE Keyboard Layout Switcher" = {
                  "Switch to Next Keyboard Layout" = "Meta+Alt+K";
                };
                kaccess = {
                  "Toggle Screen Reader On and Off" = "Meta+Alt+S";
                };
                kcm_touchpad = {
                  "Disable Touchpad" = "Touchpad Off";
                  "Enable Touchpad" = "Touchpad On";
                  "Toggle Touchpad" = "Touchpad Toggle";
                };
                kded5 = {
                  "Show System Activity" = "Ctrl+Esc";
                  "display" = ["Display" "Meta+P"];
                };
                kmix = {
                  decrease_microphone_volume = "Microphone Volume Down";
                  decrease_volume = "Volume Down";
                  increase_microphone_volume = "Microphone Volume Up";
                  increase_volume = "Volume Up";
                  mic_mute = ["Microphone Mute" "Meta+Volume Mute"];
                  mute = "Volume Mute";
                };
                ksmserver = {
                  "Halt Without Confirmation" = [];
                  "Lock Session" = [];
                  "Log Out Without Confirmation" = [];
                  "Reboot Without Confirmation" = [];
                };
                "org.kde.krunner.desktop" = {
                  "RunClipboard" = "Alt+Shift+F2";
                  "_launch" = ["Meta+D"];
                };
                "org.kde.plasma.emojier.desktop" = {
                  "_launch" = ["Meta+." "Meta+Ctrl+Alt+Shift+Space"];
                };
                "org_kde_powerdevil" = {
                  "Decrease Keyboard Brightness" = "Keyboard Brightness Down";
                  "Decrease Screen Brightness" = "Monitor Brightness Down";
                  "Hibernate" = "Hibernate";
                  "Increase Keyboard Brightness" = "Keyboard Brightness Up";
                  "Increase Screen Brightness" = "Monitor Brightness Up";
                  "PowerDown" = "Power Down";
                  "PowerOff" = "Power Off";
                  "Sleep" = "Sleep";
                  "Toggle Keyboard Backlight" = "Keyboard Light On/Off";
                  "Turn Off Screen" = [];
                };
                "systemsettings.desktop" = {
                  "_launch" = "Tools";
                  "kcm-kscreen" = [];
                  "kcm-lookandfeel" = [];
                  "kcm-users" = [];
                  "powerdevilprofilesconfig" = [];
                  "screenlocker" = [];
                };
              };
              panels = [
                {
                  location = "bottom";
                  floating = true;
                  height = 40;

                  widgets = [
                    {
                      kickoff = {
                        icon = "nix-snowflake";
                        sortAlphabetically = true;
                      };
                    }

                    {
                      iconTasks = {
                        appearance = {
                          fill = false;
                          highlightWindows = true;
                          iconSpacing = "medium";
                          indicateAudioStreams = true;
                          showTooltips = true;
                        };
                        behavior = {
                          grouping = {
                            clickAction = "showPresentWindowsEffect";
                            method = "byProgramName";
                          };
                          middleClickAction = "newInstance";
                          minimizeActiveTaskOnClick = true;
                          newTasksAppearOn = "right";
                          showTasks = {
                            onlyInCurrentActivity = true;
                            onlyInCurrentDesktop = true;
                            onlyMinimized = false;
                            onlyInCurrentScreen = false;
                          };
                          unhideOnAttentionNeeded = true;
                          wheel = {
                            ignoreMinimizedTasks = true;
                            switchBetweenTasks = true;
                          };
                        };
                        launchers = [
                          "applications:systemsettings.desktop"
                          "applications:thunderbird.desktop"
                          "applications:kitty.desktop"
                          "applications:yazi.desktop"
                          "applications:code.desktop"
                          "preferred://browser"
                        ];
                      };
                    }
                    "org.kde.plasma.panelspacer"
                    "org.kde.plasma.marginsseparator"
                    {
                      systemTray = {
                        icons = {
                          scaleToFit = true;
                          spacing = "small";
                        };
                        items = {
                          showAll = false;
                          shown = [
                            "org.kde.plasma.volume"
                          ];
                          hidden = [
                            "org.kde.plasma.clipboard"
                            "org.kde.plasma.bluetooth"
                          ];
                        };
                      };
                    }
                    {
                      digitalClock = {
                        date.enable = false;
                        time.format = "24h";
                        font = {
                          family = "Iosevka";
                          size = 12;
                          weight = 400;
                          italic = false;
                          style = "Medium";
                        };
                        calendar.firstDayOfWeek = "monday";
                      };
                    }
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
                tiling = {
                  padding = 15;
                  layout = {
                    id = "82dece0e-5d1e-527e-a891-21c2c84c6f64";
                    tiles = {
                      layoutDirection = "horizontal";
                      tiles = [
                        {
                          width = 0.5;
                        }
                        {
                          layoutDirection = "vertical";
                          tiles = [
                            {
                              height = 0.5;
                            }
                            {
                              height = 0.5;
                            }
                          ];
                          width = 0.5;
                        }
                      ];
                    };
                  };
                };
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
                    animation = "squash";
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
                };
              };
              fonts = {
                general = {
                  family = "Iosevka";
                  pointSize = 10;
                };
                fixedWidth = {
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
          kwallet
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
