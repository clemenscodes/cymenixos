{
  inputs,
  pkgs,
  lib,
  ...
}: {config, ...}: let
  cfg = config.modules;
in {
  imports = [
    (import ./monero {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      crypto = {
        enable = lib.mkEnableOption "Enable crypto modules" // {default = false;};
      };
    };
  };
}
