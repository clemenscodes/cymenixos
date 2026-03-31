{
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://attic.xuyh0120.win/lantian"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    ];
  };
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    nixpkgs-electron-fix = {
      url = "github:NixOS/nixpkgs/master";
      flake = false;
    };
    impermanence = {
      url = "github:nix-community/impermanence";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    nixvirt = {
      url = "github:clemenscodes/NixVirt";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
        home-manager = {
          follows = "home-manager";
        };
      };
    };
    anyrun = {
      url = "github:anyrun-org/anyrun";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    cymenixvim = {
      url = "github:clemenscodes/cymenixvim";
    };
    xremap-flake = {
      url = "github:xremap/nix-flake/8001f37b1ffe86e76b62f36afadee2f4acf90e70";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    pwndbg = {
      url = "github:pwndbg/pwndbg";
    };
    joymouse = {
      url = "github:clemenscodes/joymouse-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    umu = {
      url = "github:Open-Wine-Components/umu-launcher?dir=packaging/nix";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    lutris-overlay = {
      url = "github:clemenscodes/lutris-overlay";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    yubikey-guide = {
      url = "github:drduh/YubiKey-Guide";
      flake = false;
    };
    w3c = {
      url = "github:clemenscodes/W3ChampionsOnLinux";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    peon-ping = {
      url = "github:clemenscodes/peon-ping";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    claude = {
      url = "github:sadjow/claude-code-nix";
    };
    codex = {
      url = "github:sadjow/codex-cli-nix";
    };
    zed = {
      url = "github:zed-industries/zed/v0.225.13";
    };
    voxtype = {
      url = "github:peteonrails/voxtype";
    };
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      inherit (pkgs) lib;
      system = "x86_64-linux";
      overlays = import ./overlays {
        inherit
          inputs
          pkgs
          lib
          system
          ;
      };
      electronOverlay = final: prev: {
        inherit
          (
            (import inputs.nixpkgs-electron-fix {
              inherit system;
              config.allowUnfree = true;
            })
          )
          electron_39
          ;
      };
      pkgs = import nixpkgs {
        inherit system;
        overlays = overlays ++ [
          inputs.nix-cachyos-kernel.overlays.default
          electronOverlay
        ];
        config = {
          allowUnfreePredicate =
            pkg:
            builtins.elem (lib.getName pkg) [
              "nvidia-x11"
              "nvidia-settings"
              "nvidia-persistenced"
            ];
        };
      };
    in
    {
      formatter = {
        ${system} = pkgs.alejandra;
      };

      packages = {
        ${system} = {
          inherit pkgs;
          inherit (pkgs) tongo;
        };
      };

      overlays = {
        ${system} = {
          default = overlays;
        };
      };

      devShells = {
        ${system} = {
          default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
              cymenixos-scripts
              nil
              alejandra
            ];
          };
        };
      };

      nixosModules = {
        ${system} = {
          default = import ./modules {
            inherit inputs pkgs lib;
            cymenixos = self;
          };
        };
      };
    };
}
