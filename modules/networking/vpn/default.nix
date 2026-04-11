{
  inputs,
  pkgs,
  lib,
  ...
}: {...}: let
  mullvad-ensure-connected = pkgs.writeShellApplication {
    name = "mullvad-ensure-connected";
    runtimeInputs = [pkgs.mullvad];
    text = ''
      if mullvad status 2>/dev/null | grep -q "^Connected"; then
        exit 0
      fi
      mullvad connect
    '';
  };
  mullvad-ensure-disconnected = pkgs.writeShellApplication {
    name = "mullvad-ensure-disconnected";
    runtimeInputs = [pkgs.mullvad];
    text = ''
      if mullvad status 2>/dev/null | grep -q "^Disconnected"; then
        exit 0
      fi
      mullvad disconnect
    '';
  };
in {
  imports = [
    (import ./thm {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      networking = {
        vpn = {
          enable =
            lib.mkEnableOption "Enable vpn"
            // {
              default = false;
            };
          scripts = {
            mullvad-ensure-connected = lib.mkOption {
              type = lib.types.package;
              readOnly = true;
              description = "mullvad-ensure-connected script derivation.";
            };
            mullvad-ensure-disconnected = lib.mkOption {
              type = lib.types.package;
              readOnly = true;
              description = "mullvad-ensure-disconnected script derivation.";
            };
          };
        };
      };
    };
  };
  config = {
    modules.networking.vpn.scripts = {inherit mullvad-ensure-connected mullvad-ensure-disconnected;};
    environment.systemPackages = [
      mullvad-ensure-connected
      mullvad-ensure-disconnected
    ];
  };
}
