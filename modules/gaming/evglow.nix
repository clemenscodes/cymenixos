{
  inputs,
  lib,
  ...
}:
{
  config,
  ...
}:
let
  cfg = config.modules.gaming.evglow;
in
{
  imports = [ inputs.evglow.nixosModules.evglow ];

  options = {
    modules = {
      gaming = {
        evglow = {
          enable = lib.mkEnableOption "evglow keyboard visualizer" // { default = false; };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.evglow = {
      enable = true;
      user = config.modules.users.user;
      layout = "qwertz";
      deviceNames = [ "xremap" ];
      class = "gamescope";
      title = "Counter-Strike 2";
    };
  };
}
