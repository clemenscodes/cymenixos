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
    environment = {
      systemPackages = [inputs.xremap-flake.packages.${system}.xremap-hypr];
    };
    services = {
      xremap = {
        enable = cfg.enable && cfg.xremap.enable && config.modules.display.gui != "headless";
        withHypr = config.modules.display.hyprland.enable;
        userName = config.modules.users.name;
        watch = true;
        yamlConfig = ''
          modmap:
            - name: "Better CapsLock"
              remap:
                CapsLock:
                  held: SUPER_L
                  alone: ESC
                  alone_timeout_millis: 500
        '';
      };
    };
  };
}
