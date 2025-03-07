{
  inputs,
  lib,
  ...
}: {
  system,
  config,
  osConfig,
  ...
}: let
  cfg = config.modules.browser;
  user = osConfig.modules.users.user;
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["untrap-for-youtube"];
    };
    overlays = [inputs.nur.overlays.default];
  };
in {
  options = {
    modules = {
      browser = {
        firefox = {
          enable = lib.mkEnableOption "Enable firefox" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.firefox.enable) {
    home = {
      persistence = {
        "${osConfig.modules.boot.impermanence.persistPath}${config.home.homeDirectory}" = {
          directories = [
            ".mozilla"
          ];
        };
      };
    };
    programs = {
      firefox = {
        inherit (cfg.firefox) enable;
        package = pkgs.wrapFirefox (
          pkgs.firefox-unwrapped.override {
            pipewireSupport = true;
          }
        ) {};
        nativeMessagingHosts = [pkgs.gnome-browser-connector];
        languagePacks = [
          "en-US"
          "de"
        ];
        policies = {
          DisableAppUpdate = true;
          DisableFirefoxStudies = true;
          DisableFirefoxAccounts = true;
          DisableTelemetry = true;
          DisableFormHistory = true;
          DisablePocket = true;
          DisableAccounts = true;
          DisableProfileImport = true;
          DisableFirefoxScreenshots = true;
          EnableTrackingProtection = {
            Value = true;
            Locked = true;
            Cryptomining = true;
            EmailTracking = true;
            Fingerprinting = true;
          };
          FirefoxHome = {
            Search = true;
            TopSites = false;
            SponsoredTopSites = false;
            Highlights = false;
            Pocket = false;
            SponsoredPocket = false;
            Snippets = false;
            Locked = true;
          };
          FirefoxSuggest = {
            WebSuggestions = false;
            SponsoredSuggestions = false;
            ImproveSuggest = false;
            Locked = true;
          };
          Homepage = {
            StartPage = "previous-session";
            Locked = true;
          };
          DNSOverHTTPS = {
            Enabled = true;
            ProviderURL = "https://adblock.dns.mullvad.net/dns-query";
            Locked = true;
          };
          PasswordManagerEnabled = false;
          PrimaryPassword = false;
          OfferToSaveLoginsDefault = false;
          OverrideFirstRunPage = "";
          OverridePostUpdatePage = "";
          DontCheckDefaultBrowser = true;
          DisplayMenuBar = "default-off";
          SearchBar = "unified";
          NoDefaultBookmarks = true;
          NetworkPrediction = false;
        };
      };
      profiles = {
        ${user} = {
          id = 0;
          name = user;
          settings = {
            "extensions.autoDisableScopes" = 0;
          };
          extensions = with pkgs.nur.repos.rycee.firefox-addons; [
            decentraleyes
            ublock-origin
            bitwarden
            istilldontcareaboutcookies
            firefox-color
            sponsorblock
            df-youtube
            untrap-for-youtube
            zotero-connector
            vimium
          ];
          search = {
            force = true;
            default = "DuckDuckGo";
            privateDefault = "DuckDuckGo";
            engines = {
              "Nix Packages" = {
                urls = [
                  {
                    template = "https://search.nixos.org/packages";
                    params = [
                      {
                        name = "type";
                        value = "packages";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = ["nix"];
              };
              "MyNixOS" = {
                urls = [
                  {
                    template = "https://mynixos.com/search";
                    params = [
                      {
                        name = "q";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = ["mnix"];
              };
              "NixOS Wiki" = {
                urls = [
                  {template = "https://nixos.wiki/index.php?search={searchTerms}";}
                ];
                iconUpdateURL = "https://nixos.wiki/favicon.png";
                updateInterval = 24 * 60 * 60 * 1000;
                definedAliases = ["nw"];
              };
              "Google" = {
                metadata = {
                  hidden = true;
                  alias = "@g";
                };
              };
            };
          };
          bookmarks = import ./bookmarks;
          userChrome = ''
            /* Sidebery settings:
            #root.root {--general-border-radius: 8px;}
            #root.root:not(:hover) .TabsPanel {--tabs-indent: 0px;}
            #root.root .PinnedTabsBar {flex-wrap: nowrap;}
            */

            /* Adapted from https://github.com/MrOtherGuy/firefox-csshacks/tree/master/chrome/autohide_sidebar.css
            Above file is available under Mozilla Public License v. 2.0
            See the above repository for updates as well as full license text. */

            /* Disable tabs bar, sidebar splitter and header */
            #TabsToolbar,
            #sidebar-header,
            #sidebar-splitter {
              display: none !important;
            }

            /* Show sidebar only when the cursor is over it
               The border controlling sidebar width will be removed so you'll need to modify
               these values to change width
            */
            #sidebar-box {
              --uc-sidebar-width: 34px;
              --uc-sidebar-hover-width: 210px;
              --uc-autohide-sidebar-delay: 50ms;
              --uc-autohide-transition-duration: 100ms;
              --uc-autohide-transition-type: ease-out;
              position: relative;
              min-width: var(--uc-sidebar-width) !important;
              width: var(--uc-sidebar-width) !important;
              max-width: var(--uc-sidebar-width) !important;
              z-index: 1;
            }

            #sidebar-box[positionend] {
              direction: rtl;
            }
            #sidebar-box[positionend] > * {
              direction: ltr;
            }

            #sidebar-box[positionend]:-moz-locale-dir(rtl) {
              direction: ltr;
            }
            #sidebar-box[positionend]:-moz-locale-dir(rtl) > * {
              direction: rtl;
            }

            #main-window[sizemode="fullscreen"] #sidebar-box {
              --uc-sidebar-width: 1px;
            }

            #sidebar {
              transition: min-width var(--uc-autohide-transition-duration) var(--uc-autohide-transition-type) var(--uc-autohide-sidebar-delay) !important;
              min-width: var(--uc-sidebar-width) !important;
              will-change: min-width;
            }

            #sidebar-box:hover > #sidebar {
              min-width: var(--uc-sidebar-hover-width) !important;
              transition-delay: 0ms !important;
            }

            .sidebar-panel {
              background-color: transparent !important;
              color: var(--newtab-text-primary-color) !important;
            }

            .sidebar-panel #search-box {
              -moz-appearance: none !important;
              background-color: rgba(249, 249, 250, 0.1) !important;
              color: inherit !important;
            }

            /* Move statuspanel to the other side when sidebar is hovered so it doesn't get covered by sidebar */

            #sidebar-box:not([positionend]):hover ~ #appcontent #statuspanel {
              inset-inline: auto 0px !important;
            }
            #sidebar-box:not([positionend]):hover ~ #appcontent #statuspanel-label {
              margin-inline: 0px !important;
              border-left-style: solid !important;
            }
          '';
          userContent = ''
            # CSS
          '';
        };
      };
    };
    xdg = {
      mimeApps = {
        associations = {
          added = lib.mkIf (cfg.defaultBrowser == "firefox") {
            "x-scheme-handler/http" = ["firefox.desktop"];
            "x-scheme-handler/https" = ["firefox.desktop"];
            "x-scheme-handler/chrome" = ["firefox.desktop"];
            "text/html" = ["firefox.desktop"];
            "application/x-extension-htm" = ["firefox.desktop"];
            "application/x-extension-html" = ["firefox.desktop"];
            "application/x-extension-shtml" = ["firefox.desktop"];
            "application/xhtml+xml" = ["firefox.desktop"];
            "application/x-extension-xhtml" = ["firefox.desktop"];
            "application/x-extension-xht" = ["firefox.desktop"];
          };
        };
        defaultApplications = lib.mkIf (cfg.defaultBrowser == "firefox") {
          "x-scheme-handler/http" = ["firefox.desktop"];
          "x-scheme-handler/https" = ["firefox.desktop"];
          "x-scheme-handler/chrome" = ["firefox.desktop"];
          "text/html" = ["firefox.desktop"];
          "application/x-extension-htm" = ["firefox.desktop"];
          "application/x-extension-html" = ["firefox.desktop"];
          "application/x-extension-shtml" = ["firefox.desktop"];
          "application/xhtml+xml" = ["firefox.desktop"];
          "application/x-extension-xhtml" = ["firefox.desktop"];
          "application/x-extension-xht" = ["firefox.desktop"];
        };
      };
      desktopEntries = {
        firefox = {
          name = "Firefox";
          genericName = "Web Browser";
          exec = "firefox %U";
          icon = "firefox";
          terminal = false;
          categories = ["Application" "Network" "WebBrowser"];
          mimeType = ["text/html" "text/xml"];
        };
      };
    };
  };
}
