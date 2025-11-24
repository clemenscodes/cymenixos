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
          home = {
            file = lib.genAttrs [] (_: {
              force = true;
              mutable = true;
            });
          };
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
                "yazi.desktop"."_launch" = "Meta+E";
                "rofi.desktop"."_launch" = "Meta+D";
                "thunderbird.desktop"."_launch" = "Meta+Shift+E";
                "services/org.kde.konsole.desktop"."_launch" = "None";
                "services/org.kde.spectacle.desktop"."ActiveWindowScreenShot" = [];
                "services/org.kde.spectacle.desktop"."FullScreenScreenShot" = "Meta+Shift+S";
                "services/org.kde.spectacle.desktop"."RectangularRegionScreenShot" = "Meta+S";
                "services/org.kde.spectacle.desktop"."WindowUnderCursorScreenShot" = "Meta+Alt+S";
                "services/org.kde.spectacle.desktop"."_launch" = "Print";
                "kwin"."Overview" = "Meta+Space";
                "kwin"."Show Desktop" = "Meta+Shift+D";
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
                "kwin"."Window Fullscreen" = ["Meta+F"];
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
                "ActivityManager"."switch-to-activity-b155094f-8179-4234-8069-7a86c76acadf" = [];
                "KDE Keyboard Layout Switcher"."Switch to Next Keyboard Layout" = "Meta+Alt+K";
                "kaccess"."Toggle Screen Reader On and Off" = "Meta+Alt+S";
                "kcm_touchpad"."Disable Touchpad" = "Touchpad Off";
                "kcm_touchpad"."Enable Touchpad" = "Touchpad On";
                "kcm_touchpad"."Toggle Touchpad" = "Touchpad Toggle";
                "kded5"."Show System Activity" = "Ctrl+Esc";
                "kded5"."display" = ["Display" "Meta+P"];
                "khotkeys"."{d03619b6-9b3c-48cc-9d9c-a2aadb485550}" = [];
                "kmix"."decrease_microphone_volume" = "Microphone Volume Down";
                "kmix"."decrease_volume" = "Volume Down";
                "kmix"."increase_microphone_volume" = "Microphone Volume Up";
                "kmix"."increase_volume" = "Volume Up";
                "kmix"."mic_mute" = ["Microphone Mute" "Meta+Volume Mute"];
                "kmix"."mute" = "Volume Mute";
                "ksmserver"."Halt Without Confirmation" = [];
                "ksmserver"."Lock Session" = [];
                "ksmserver"."Log Out Without Confirmation" = [];
                "ksmserver"."Reboot Without Confirmation" = [];
                "kwin"."Activate Window Demanding Attention" = "Meta+Ctrl+A";
                "kwin"."Decrease Opacity" = [];
                "kwin"."Edit Tiles" = "Meta+T";
                "kwin"."Expose" = "Ctrl+F9";
                "kwin"."ExposeAll" = ["Ctrl+F10" "Launch (C)"];
                "kwin"."ExposeClass" = "Ctrl+F7";
                "kwin"."ExposeClassCurrentDesktop" = [];
                "kwin"."Increase Opacity" = [];
                "kwin"."MoveMouseToCenter" = "Meta+F6";
                "kwin"."MoveMouseToFocus" = "Meta+F5";
                "kwin"."MoveZoomDown" = [];
                "kwin"."MoveZoomLeft" = [];
                "kwin"."MoveZoomRight" = [];
                "kwin"."MoveZoomUp" = [];
                "kwin"."Setup Window Shortcut" = [];
                "kwin"."ShowDesktopGrid" = "Meta+F8";
                "kwin"."Suspend Compositing" = "Alt+Shift+F12";
                "kwin"."Switch One Desktop Down" = [];
                "kwin"."Switch One Desktop Up" = [];
                "kwin"."Switch One Desktop to the Left" = [];
                "kwin"."Switch One Desktop to the Right" = [];
                "kwin"."Switch Window Down" = "Meta+Alt+Down";
                "kwin"."Switch Window Left" = "Meta+Alt+Left";
                "kwin"."Switch Window Right" = "Meta+Alt+Right";
                "kwin"."Switch Window Up" = "Meta+Alt+Up";
                "kwin"."Switch to Desktop 11" = [];
                "kwin"."Switch to Desktop 12" = [];
                "kwin"."Switch to Desktop 13" = [];
                "kwin"."Switch to Desktop 14" = [];
                "kwin"."Switch to Desktop 15" = [];
                "kwin"."Switch to Desktop 16" = [];
                "kwin"."Switch to Desktop 17" = [];
                "kwin"."Switch to Desktop 18" = [];
                "kwin"."Switch to Desktop 19" = [];
                "kwin"."Switch to Desktop 20" = [];
                "kwin"."Switch to Next Desktop" = [];
                "kwin"."Switch to Next Screen" = [];
                "kwin"."Switch to Previous Desktop" = [];
                "kwin"."Switch to Previous Screen" = [];
                "kwin"."Toggle Night Color" = [];
                "kwin"."Toggle Window Raise/Lower" = [];
                "kwin"."Walk Through Desktop List" = [];
                "kwin"."Walk Through Desktop List (Reverse)" = [];
                "kwin"."Walk Through Desktops" = [];
                "kwin"."Walk Through Desktops (Reverse)" = [];
                "kwin"."Walk Through Windows" = "Alt+Tab";
                "kwin"."Walk Through Windows (Reverse)" = "Alt+Shift+Backtab";
                "kwin"."Walk Through Windows Alternative" = [];
                "kwin"."Walk Through Windows Alternative (Reverse)" = [];
                "kwin"."Walk Through Windows of Current Application" = "Alt+`";
                "kwin"."Walk Through Windows of Current Application (Reverse)" = "Alt+~";
                "kwin"."Walk Through Windows of Current Application Alternative" = [];
                "kwin"."Walk Through Windows of Current Application Alternative (Reverse)" = [];
                "kwin"."Window Above Other Windows" = [];
                "kwin"."Window Below Other Windows" = [];
                "kwin"."Window Grow Horizontal" = [];
                "kwin"."Window Grow Vertical" = [];
                "kwin"."Window Lower" = [];
                "kwin"."Window Maximize" = "Meta+PgUp";
                "kwin"."Window Maximize Horizontal" = [];
                "kwin"."Window Maximize Vertical" = [];
                "kwin"."Window Minimize" = "Meta+PgDown";
                "kwin"."Window Move" = [];
                "kwin"."Window Move Center" = [];
                "kwin"."Window No Border" = [];
                "kwin"."Window On All Desktops" = [];
                "kwin"."Window One Desktop Down" = "Meta+Ctrl+Shift+Down";
                "kwin"."Window One Desktop Up" = "Meta+Ctrl+Shift+Up";
                "kwin"."Window One Desktop to the Left" = "Meta+Ctrl+Shift+Left";
                "kwin"."Window One Desktop to the Right" = "Meta+Ctrl+Shift+Right";
                "kwin"."Window One Screen Down" = [];
                "kwin"."Window One Screen Up" = [];
                "kwin"."Window One Screen to the Left" = [];
                "kwin"."Window One Screen to the Right" = [];
                "kwin"."Window Operations Menu" = "Alt+F3";
                "kwin"."Window Pack Down" = [];
                "kwin"."Window Pack Left" = [];
                "kwin"."Window Pack Right" = [];
                "kwin"."Window Pack Up" = [];
                "kwin"."Window Quick Tile Bottom" = "Meta+Down";
                "kwin"."Window Quick Tile Bottom Left" = [];
                "kwin"."Window Quick Tile Bottom Right" = [];
                "kwin"."Window Quick Tile Left" = "Meta+Left";
                "kwin"."Window Quick Tile Right" = "Meta+Right";
                "kwin"."Window Quick Tile Top" = "Meta+Up";
                "kwin"."Window Quick Tile Top Left" = [];
                "kwin"."Window Quick Tile Top Right" = [];
                "kwin"."Window Raise" = [];
                "kwin"."Window Resize" = [];
                "kwin"."Window Shade" = [];
                "kwin"."Window to Desktop 11" = [];
                "kwin"."Window to Desktop 12" = [];
                "kwin"."Window to Desktop 13" = [];
                "kwin"."Window to Desktop 14" = [];
                "kwin"."Window to Desktop 15" = [];
                "kwin"."Window to Desktop 16" = [];
                "kwin"."Window to Desktop 17" = [];
                "kwin"."Window to Desktop 18" = [];
                "kwin"."Window to Desktop 19" = [];
                "kwin"."Window to Desktop 20" = [];
                "kwin"."Window to Next Desktop" = [];
                "kwin"."Window to Next Screen" = "Meta+Shift+Right";
                "kwin"."Window to Previous Desktop" = [];
                "kwin"."Window to Previous Screen" = "Meta+Shift+Left";
                "kwin"."view_actual_size" = "Meta+0";
                "kwin"."view_zoom_in" = ["Meta++" "Meta+="];
                "kwin"."view_zoom_out" = "Meta+-";
                "org.kde.krunner.desktop"."RunClipboard" = "Alt+Shift+F2";
                "org.kde.krunner.desktop"."_launch" = ["Meta+D"];
                "org.kde.plasma.emojier.desktop"."_launch" = ["Meta+." "Meta+Ctrl+Alt+Shift+Space"];
                "org_kde_powerdevil"."Decrease Keyboard Brightness" = "Keyboard Brightness Down";
                "org_kde_powerdevil"."Decrease Screen Brightness" = "Monitor Brightness Down";
                "org_kde_powerdevil"."Hibernate" = "Hibernate";
                "org_kde_powerdevil"."Increase Keyboard Brightness" = "Keyboard Brightness Up";
                "org_kde_powerdevil"."Increase Screen Brightness" = "Monitor Brightness Up";
                "org_kde_powerdevil"."PowerDown" = "Power Down";
                "org_kde_powerdevil"."PowerOff" = "Power Off";
                "org_kde_powerdevil"."Sleep" = "Sleep";
                "org_kde_powerdevil"."Toggle Keyboard Backlight" = "Keyboard Light On/Off";
                "org_kde_powerdevil"."Turn Off Screen" = [];
                "plasmashell"."clear-history" = [];
                "plasmashell"."clipboard_action" = "Meta+Ctrl+X";
                "plasmashell"."cycle-panels" = "Meta+Alt+P";
                "plasmashell"."cycleNextAction" = [];
                "plasmashell"."cyclePrevAction" = [];
                "plasmashell"."edit_clipboard" = [];
                "plasmashell"."next activity" = "Meta+Shift+Tab";
                "plasmashell"."previous activity" = "Meta+Shift+Tab";
                "plasmashell"."repeat_action" = "Meta+Ctrl+R";
                "plasmashell"."show dashboard" = "Ctrl+F12";
                "plasmashell"."show-barcode" = [];
                "plasmashell"."show-on-mouse-pos" = "Meta+V";
                "plasmashell"."switch to next activity" = [];
                "plasmashell"."switch to previous activity" = [];
                "plasmashell"."toggle do not disturb" = [];
                "systemsettings.desktop"."_launch" = "Tools";
                "systemsettings.desktop"."kcm-kscreen" = [];
                "systemsettings.desktop"."kcm-lookandfeel" = [];
                "systemsettings.desktop"."kcm-users" = [];
                "systemsettings.desktop"."powerdevilprofilesconfig" = [];
                "systemsettings.desktop"."screenlocker" = [];
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
                          "preferred://browser"
                          "applications:thunderbird.desktop"
                          "applications:kitty.desktop"
                          "applications:yazi.desktop"
                          "applications:code.desktop"
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
                      digitalClock = {
                        date.enable = false;
                        time.showSeconds = "onlyInTooltip";
                        calendar.showWeekNumbers = true;
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
