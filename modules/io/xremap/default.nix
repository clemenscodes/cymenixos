{
  inputs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.io;
in {
  imports = [inputs.xremap-flake.nixosModules.default];
  options = {
    modules = {
      io = {
        xremap = {
          enable = lib.mkEnableOption "Enable xremap system service" // {default = false;};
        };
      };
    };
  };
  config = {
    users = {
      users = {
        "${config.modules.users.name}" = {
          extraGroups = ["uinput" "input"];
        };
      };
    };
    environment = {
      systemPackages = [inputs.xremap-flake.packages.${system}.xremap-hypr];
    };
    systemd = {
      user = {
        services = {
          xremap = {
            wantedBy = ["default.target"];
          };
        };
      };
    };
    services = {
      xremap = {
        enable = cfg.enable && cfg.xremap.enable && config.modules.display.gui != "headless";
        withHypr = config.modules.display.hyprland.enable;
        userName = config.modules.users.name;
        serviceMode = "user";
        watch = true;
        yamlConfig = ''
          modmap:
            - name: "Better CapsLock"
              remap:
                CapsLock:
                  held: SUPER_L
                  alone: ESC
                  alone_timeout_millis: 120
        '';
      };
      udev = {
        extraRules = ''
          KERNEL=="uinput", GROUP="input", TAG+="uaccess"
        '';
      };
    };
  };
}
