{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
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
    nvim = {
      url = "github:cymenix/nvim";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    xremap-flake = {
      url = "github:xremap/nix-flake";
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
      url = "github:clemenscodes/lanzaboote";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    umu = {
      url = "git+https://github.com/Open-Wine-Components/umu-launcher/?dir=packaging\/nix&submodules=1";
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
    lpi = {
      url = "github:cymenix/lpi";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    cardanix = {
      url = "github:clemenscodes/cardanix";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    templates = {
      url = "github:NixOS/templates";
    };
    # For fetch-closure shrunk release packages with minimal eval time and dependency sizes
    # Currently x86_64-linux only
    capkgs = {
      url = "github:input-output-hk/capkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      overlays = [] ++ (import ./overlays);
    };
    inherit (pkgs) lib;
  in {
    formatter = {
      ${system} = pkgs.alejandra;
    };

    packages = {
      ${system} = {
        inherit (pkgs) grub2;
      };
    };

    overlays = {
      ${system} = {
        default = import ./overlays;
      };
    };

    devShells = {
      ${system} = {
        default = pkgs.mkShell {
          nativeBuildInputs = [pkgs.cymenixos-scripts];
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
