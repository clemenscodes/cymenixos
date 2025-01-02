{
  inputs,
  pkgs,
  lib,
  ...
}: {
  config,
  self,
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
    nix = {
      nixPath = ["nixpkgs=${pkgs.path}"];
      registry = {
        self = {
          flake = self;
        };
        nixpkgs = {
          from = {
            id = "nixpkgs";
            type = "indirect";
          };
          flake = inputs.nixpkgs;
        };
      };
      gc = {
        automatic = lib.mkDefault false;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };
      optimise = {
        automatic = true;
      };
      daemonCPUSchedPolicy = "idle";
      daemonIOSchedClass = "idle";
      extraOptions = ''
        accept-flake-config = true
      '';
      settings = {
        auto-optimise-store = true;
        builders-use-substitutes = true;
        keep-going = true;
        allowed-users = ["@wheel"];
        trusted-users = ["@wheel"];
        experimental-features = [
          "nix-command"
          "flakes"
          "fetch-closure"
        ];
        substituters = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
          "https://nix-gaming.cachix.org"
          "https://cache.iog.io"
          "https://nixpkgs-unfree.cachix.org"
          "https://clemenscodes.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
          "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
          "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
          "clemenscodes.cachix.org-1:yEwW1YgttL2xdsyfFDz/vv8zZRhRGMeDQsKKmtV1N18="
        ];
      };
    };
  };
}
