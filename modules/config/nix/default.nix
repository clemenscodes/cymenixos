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
  cfg = config.modules.config;
in {
  options = {
    modules = {
      config = {
        nix = {
          enable = lib.mkEnableOption "Enable common nix options" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.nix.enable) {
    environment = {
      defaultPackages = lib.mkForce [];
    };
    nixpkgs = {
      inherit pkgs;
      hostPlatform = system;
    };
    nix = {
      registry = lib.mapAttrs (_: value: {flake = value;}) inputs;
      nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
      channel = {
        enable = false;
      };
      settings = {
        flake-registry = "/etc/nix/registry.json";
        auto-optimise-store = true;
        builders-use-substitutes = true;
        keep-going = true;
        allowed-users = ["@wheel"];
        trusted-users = ["@wheel"];
        substituters = ["https://nix-community.cachix.org"];
        trusted-public-keys = ["nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="];
        experimental-features = ["nix-command" "flakes" "fetch-closure"];
      };
      gc = {
        automatic = lib.mkDefault false;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };
      optimise = {
        automatic = true;
      };
      extraOptions = ''
        accept-flake-config = true
      '';
      daemonCPUSchedPolicy = "idle";
      daemonIOSchedClass = "idle";
    };
    system = {
      autoUpgrade = {
        enable = false;
      };
    };
  };
}
