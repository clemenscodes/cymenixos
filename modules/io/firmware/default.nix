{lib, ...}: {config, ...}: let
  cfg = config.modules.io;
in {
  options = {
    modules = {
      io = {
        firmware = {
          enable =
            lib.mkEnableOption "Firmware updates via fwupd (LVFS)";
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.firmware.enable) {
    services.fwupd.enable = true;
    # fwupd ships org.freedesktop.fwupd.refresh-remote with allow_inactive=no,
    # so the fwupd-refresh system service user is denied by polkit even though
    # fwupd intentionally creates that user for the timer. Add an explicit rule.
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id === "org.freedesktop.fwupd.refresh-remote" &&
            subject.user === "fwupd-refresh") {
          return polkit.Result.YES;
        }
      });
    '';
  };
}
