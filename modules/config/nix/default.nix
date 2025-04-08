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
      persistence = {
        ${config.modules.boot.impermanence.persistPath} = {
          users = {
            ${config.modules.users.name} = {
              directories = [".cache/nix"];
            };
          };
        };
      };
    };
    nixpkgs = {
      inherit pkgs;
      hostPlatform = system;
    };
    nix = {
      registry = lib.mkIf (!config.modules.airgap.enable) (lib.mapAttrs (_: value: {flake = value;}) inputs);
      nixPath = lib.mkIf (!config.modules.airgap.enable) (lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry);
      channel = {
        enable = false;
      };
      settings = {
        flake-registry = lib.mkIf (!config.modules.airgap.enable) "/etc/nix/registry.json";
        auto-optimise-store = true;
        builders-use-substitutes = true;
        keep-going = true;
        keep-outputs = true;
        allowed-users = ["@wheel"];
        trusted-users = ["@wheel"];
        substituters = lib.mkIf (!config.modules.airgap.enable) ["https://nix-community.cachix.org"];
        trusted-public-keys = lib.mkIf (!config.modules.airgap.enable) ["nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="];
        experimental-features = ["nix-command" "flakes" "fetch-closure"];
      };
      gc = lib.mkIf (!config.modules.airgap.enable) {
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
