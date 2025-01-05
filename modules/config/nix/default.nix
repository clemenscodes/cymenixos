{
  lib,
  cymenixos,
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
    nixpkgs = {
      hostPlatform = system;
      flake = {
        source = lib.mkForce cymenixos.outPath;
      };
    };
    nix = {
      nixPath = ["nixpkgs=${cymenixos.outPath}"];
      registry = {
        nixpkgs = {
          from = {
            id = "nixpkgs";
            type = "indirect";
          };
          to = {
            type = "github";
            owner = "clemenscodes";
            repo = "cymenixos";
          };
          flake = cymenixos;
        };
      };
      channel = {
        enable = false;
      };
      settings = {
        auto-optimise-store = true;
        builders-use-substitutes = true;
        keep-going = true;
        allowed-users = ["@wheel"];
        trusted-users = ["@wheel"];
        experimental-features = ["nix-command" "flakes" "fetch-closure"];
        substituters = ["https://nix-community.cachix.org"];
        trusted-public-keys = ["nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="];
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
  };
}
