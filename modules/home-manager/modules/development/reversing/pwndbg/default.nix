{
  inputs,
  pkgs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules.development.reversing;
in {
  options = {
    modules = {
      development = {
        reversing = {
          pwndbg = {
            enable = lib.mkEnableOption "Enable pwndbg" // {default = false;};
          };
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.pwndbg.enable) {
    home = {
      packages = [
        pkgs.gdb
        pkgs.lldb
        inputs.pwndbg.packages.${system}.pwndbg
        inputs.pwndbg.packages.${system}.pwndbg-lldb
      ];
    };
  };
}
