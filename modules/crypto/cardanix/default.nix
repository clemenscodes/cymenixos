{
  inputs,
  lib,
  ...
}: let
  module = "crypto";
  submodule = "cardanix";
  imports = [inputs.cardanix.nixosModules.x86_64-linux];
  declarations = {
    cardano = {
      enable = true;
      bech32 = {
        enable = true;
      };
      address = {
        enable = true;
      };
      cli = {
        enable = true;
      };
      node = {
        enable = true;
        submit-api = {
          enable = true;
        };
      };
      wallet = {
        enable = true;
      };
      db-sync = {
        enable = true;
      };
      daedalus = {
        enable = false;
      };
    };
  };
in
  lib.mkSubModuleOption module submodule imports declarations
