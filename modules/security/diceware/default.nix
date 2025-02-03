{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
  inherit (cfg.security.diceware) addr port;
  dicewareScript = pkgs.writeShellScriptBin "diceware-webapp" ''
    viewer="$(type -P xdg-open || true)"
    if [ -z "$viewer" ]; then
      viewer="firefox"
    fi
    exec $viewer "http://"${lib.escapeShellArg addr}":${toString port}/index.html"
  '';
  dicewarePage = pkgs.stdenv.mkDerivation {
    name = "diceware-page";
    src = pkgs.fetchFromGitHub {
      owner = "grempe";
      repo = "diceware";
      rev = "9ef886a2a9699f73ae414e35755fd2edd69983c8";
      sha256 = "44rpK8svPoKx/e/5aj0DpEfDbKuNjroKT4XUBpiOw2g=";
    };
    patches = [
      # Include changes published on https://secure.research.vt.edu/diceware/
      "${inputs.yubikey-guide}/diceware-vt.patch"
    ];
    buildPhase = ''
      cp -a . $out
    '';
  };
  dicewareWebApp = pkgs.makeDesktopItem {
    name = "diceware";
    icon = "${dicewarePage}/favicon.ico";
    desktopName = "Diceware Passphrase Generator";
    genericName = "Passphrase Generator";
    comment = "Open the passphrase generator in a web browser";
    categories = ["Utility"];
    exec = "${dicewareScript}/bin/${dicewareScript.name}";
  };
in {
  options = {
    modules = {
      security = {
        diceware = {
          enable = lib.mkEnableOption "Enable diceware" // {default = false;};
          addr = lib.mkOption {
            type = lib.types.str;
            default = "localhost";
            example = "localhost";
            description = "The address on which to run the diceware web application";
          };
          port = lib.mkOption {
            type = lib.types.int;
            default = 8080;
            example = 8000;
            description = "The port on which to run the diceware web application";
          };
        };
      };
    };
  };
  config = lib.mkIf cfg.security.diceware.enable {
    services = {
      nginx = {
        enable = true;
        virtualHosts = {
          "diceware.local" = {
            listen = [{inherit addr port;}];
            root = "${dicewarePage}";
          };
        };
      };
    };
    programs = {
      firefox = {
        enable = true;
        preferences = {
          # Disable data reporting confirmation dialogue
          "datareporting.policy.dataSubmissionEnabled" = false;
          # Disable welcome tab
          "browser.aboutwelcome.enabled" = false;
        };
        # Make preferences appear as user-defined values
        preferencesStatus = "user";
      };
    };
    environment = {
      systemPackages = [
        pkgs.diceware
        dicewareWebApp
      ];
    };
    system = {
      activationScripts = {
        diceware = let
          homeDir = "/home/${config.modules.users.name}/";
          desktopDir = homeDir + "Desktop/";
          documentsDir = homeDir + "Documents/";
        in ''
          mkdir -p ${desktopDir} ${documentsDir}
          chown ${config.modules.users.name} ${homeDir} ${desktopDir} ${documentsDir}
          ln -sf ${dicewareWebApp}/share/applications/${dicewareWebApp.name} ${desktopDir}
        '';
      };
    };
  };
}
