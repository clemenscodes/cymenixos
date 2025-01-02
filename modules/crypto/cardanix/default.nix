{
  inputs,
  lib,
  ...
}: let
  imports = [inputs.cardanix.nixosModules.x86_64-linux];
  module = "crypto";
  submodule = "cardanix";
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
  lib.mkSubModule {inherit imports module submodule declarations;}
