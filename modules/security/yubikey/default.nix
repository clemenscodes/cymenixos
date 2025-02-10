{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  inherit (config.modules.boot.impermanence) persistPath;
  cfg = config.modules.security;
  homeDirectory = "/home/${config.modules.users.name}";
  viewYubikeyGuide = pkgs.writeShellScriptBin "view-yubikey-guide" ''
    exec ${pkgs.glow}/bin/glow -p "${inputs.yubikey-guide}/README.md"
  '';
  shortcut = pkgs.makeDesktopItem {
    name = "yubikey-guide";
    icon = "${pkgs.yubioath-flutter}/share/icons/com.yubico.yubioath.png";
    desktopName = "drduh's YubiKey Guide";
    genericName = "Guide to using YubiKey for GnuPG and SSH";
    comment = "Open the guide in a reader program";
    categories = ["Documentation"];
    terminal = true;
    exec = "${viewYubikeyGuide}/bin/view-yubikey-guide";
  };
  yubikeyGuide = pkgs.symlinkJoin {
    name = "yubikey-guide";
    paths = [viewYubikeyGuide shortcut];
  };
  yubikey-pubkey-url = import ./yubikey-pubkey-url.nix {inherit pkgs;};
  yubikey-gpg-setup = import ./yubikey-gpg-setup.nix {inherit pkgs;};
  yubikey-reset = import ./yubikey-reset.nix {inherit pkgs;};
  yubikey-up = let
    yubikeyIds = lib.concatStringsSep " " (
      lib.mapAttrsToList (name: id: "[${name}]=\"${builtins.toString id}\"") cfg.yubikey.pam.identifiers
    );
  in
    pkgs.writeShellApplication {
      name = "yubikey-up";
      runtimeInputs = [pkgs.yubikey-manager];
      text = ''
        serial=$(ykman list | awk '{print $NF}')

        if [ -z "$serial" ]; then
          exit 0
        fi

        declare -A serials=(${yubikeyIds})

        key_name=""
        for key in "''${!serials[@]}"; do
          if [[ $serial == "''${serials[$key]}" ]]; then
            key_name="$key"
          fi
        done

        if [ -z "$key_name" ]; then
          echo WARNING: Unidentified yubikey with serial "$serial" . Won\'t link an SSH key.
          exit 0
        fi

        echo "Checking and creating links to ${homeDirectory}/.ssh/id_$key_name"
        if [ -f "${homeDirectory}/.ssh/id_$key_name" ]; then
          ln -sf "${homeDirectory}/.ssh/id_$key_name" ${homeDirectory}/.ssh/id_yubikey
        fi
        if [ -f "${homeDirectory}/.ssh/id_$key_name.pub" ]; then
          ln -sf "${homeDirectory}/.ssh/id_$key_name.pub" ${homeDirectory}/.ssh/id_yubikey.pub
        fi
      '';
    };
  yubikey-down = pkgs.writeShellApplication {
    name = "yubikey-down";
    text = ''
      if [ -f "${homeDirectory}/.ssh/id_yubikey" ]; then
        rm ${homeDirectory}/.ssh/id_yubikey
      fi
      if [ -f "${homeDirectory}/.ssh/id_yubikey.pub" ]; then
        rm ${homeDirectory}/.ssh/id_yubikey.pub
      fi
      ${pkgs.systemd}/bin/loginctl lock-sessions
    '';
  };
  yubikey-scripts = pkgs.symlinkJoin {
    name = "yubikey-scripts";
    paths = [
      yubikey-pubkey-url
      yubikey-gpg-setup
      yubikey-up
      yubikey-down
      yubikey-reset
    ];
  };
in {
  options = {
    modules = {
      security = {
        yubikey = {
          enable = lib.mkEnableOption "Enable yubikey" // {default = false;};
          pam = {
            enable = lib.mkEnableOption "Enable yubikey PAM" // {default = false;};
            u2f-mappings = lib.mkOption {
              default = [];
              type = lib.types.listOf lib.types.str;
              description = "The list of u2f mappings for pam auth";
              example = lib.literalExample ''
                [
                  ":<KeyHandle1>,<UserKey1>,<CoseType1>,<Options1>"
                  ":<KeyHandle2>,<UserKey2>,<CoseType2>,<Options2>"
                ]
              '';
            };
            identifiers = lib.mkOption {
              default = {};
              type = lib.types.attrsOf lib.types.int;
              description = "Attrset of Yubikey serial numbers. NOTE: Yubico's 'Security Key' products do not use unique serial number therefore, the scripts in this module are unable to distinguish between multiple 'Security Key' devices and instead will detect a Security Key serial number as the string \"[FIDO]\". This means you can only use a single Security Key but can still mix it with YubiKey 4 and 5 devices.";
              example = lib.literalExample ''
                {
                  foo = 12345678;
                  bar = 87654321;
                  baz = "[FIDO]";
                }
              '';
            };
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.yubikey.enable) {
    boot = {
      initrd = {
        kernelModules = ["vfat" "nls_cp437" "nls_iso8859-1" "usbhid"];
        luks = {
          yubikeySupport = cfg.yubikey.enable;
        };
      };
    };
    hardware = {
      gpgSmartcards = {
        inherit (cfg.yubikey) enable;
      };
    };
    services = {
      pcscd = {
        inherit (cfg.yubikey) enable;
      };
      yubikey-agent = {
        inherit (cfg.yubikey) enable;
      };
      udev = {
        packages = [pkgs.yubikey-personalization];
        extraRules = ''
          ACTION=="add",\
           ENV{ID_BUS}=="usb",\
           ENV{ID_VENDOR_ID}=="1050",\
           ENV{ID_MODEL_ID}=="0403|0407",\
           ENV{ID_VENDOR}=="Yubico",\
           RUN+="${yubikey-up}/bin/yubikey-up"

          ACTION=="remove",\
           ENV{ID_BUS}=="usb",\
           ENV{ID_VENDOR_ID}=="1050",\
           ENV{ID_MODEL_ID}=="0403|0407",\
           ENV{ID_VENDOR}=="Yubico",\
           RUN+="${yubikey-down}/bin/yubikey-down"
        '';
      };
    };
    security = {
      pam = lib.mkIf cfg.yubikey.pam.enable {
        services = {
          login = {
            u2fAuth = true;
          };
          sudo = {
            u2fAuth = true;
            sshAgentAuth = cfg.ssh.enable;
          };
        };
        u2f = {
          inherit (cfg.yubikey.pam) enable;
          settings = {
            cue = true;
          };
        };
      };
    };
    programs = {
      yubikey-touch-detector = {
        inherit (cfg.yubikey) enable;
      };
      ssh = {
        startAgent = false;
      };
      gnupg = {
        agent = {
          inherit (cfg.yubikey) enable;
        };
      };
    };
    environment = {
      systemPackages = [
        pkgs.yubikey-manager
        pkgs.yubioath-flutter
        pkgs.yubico-piv-tool
        pkgs.yubico-pam
        pkgs.pam_u2f
        yubikeyGuide
        yubikey-scripts
      ];
      persistence = {
        "${persistPath}" = {
          users = {
            ${config.modules.users.user} = {
              directories = [
                ".config/Yubico"
                ".local/share/com.yubico.authenticator"
              ];
            };
          };
        };
      };
    };
    system = {
      activationScripts = {
        yubikey-guide = let
          homeDir = "/home/${config.modules.users.name}";
          desktopDir = "${homeDir}/Desktop";
          documentsDir = "${homeDir}/Documents";
          u2f_keys = pkgs.writeText "u2f_keys" (lib.concatStrings ([config.modules.users.name ":"] ++ [(lib.concatStrings (cfg.yubikey.pam.u2f-mappings ++ [" "]))]));
        in ''
          mkdir -p ${desktopDir} ${documentsDir} ${homeDir}/.config/Yubico
          chown ${config.modules.users.name} ${homeDir} ${desktopDir} ${documentsDir}
          ln -sf ${u2f_keys} ${homeDir}/.config/Yubico/u2f_keys
          ln -sf ${yubikeyGuide}/share/applications/yubikey-guide.desktop ${desktopDir}
          ln -sfT ${inputs.yubikey-guide} ${documentsDir}/YubiKey-Guide
        '';
      };
    };
  };
}
