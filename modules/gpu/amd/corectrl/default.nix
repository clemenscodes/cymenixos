{lib, ...}: {config, ...}: let
  cfg = config.modules.gpu.amd;
  isDesktop = config.modules.display.gui != "headless";
in {
  options = {
    modules = {
      gpu = {
        amd = {
          corectrl = {
            enable = lib.mkEnableOption "Enable corectrl for AMD GPUs" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.corectrl.enable) {
    programs = {
      corectrl = {
        inherit (cfg.corectrl) enable;
        gpuOverclock = {
          enable = true;
          ppfeaturemask = "0xfff7ffff";
        };
      };
    };
    security = {
      polkit = {
        enable = true;
        extraConfig =
          /*
          javascript
          */
          ''
            polkit.addRule(function(action, subject) {
              const isInit = action.id == "org.corectrl.helper.init" || action.id == "org.corectrl.helperkiller.init";
              const isLocal = subject.local == true;
              const isActive = subject.active == true;
              const hasUserGroup = subject.isInGroup("${config.modules.users.user}");
              if (isInit && isLocal && isActive && hasUserGroup) {
                return polkit.Result.YES;
              }
            });
          '';
      };
    };
    home-manager = lib.mkIf (config.modules.home-manager.enable && isDesktop) {
      users = {
        ${config.modules.users.user} = {
          xdg = {
            configFile = {
              "corectrl/corectrl.ini" = {
                text = ''
                  [General]
                  startOnSysTray=true
                '';
              };
            };
          };
        };
      };
    };
  };
}
