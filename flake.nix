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
    };
    cymenixvim = {
      url = "github:clemenscodes/cymenixvim";
    };
    codevim = {
      url = "github:clemenscodes/codevim";
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
      url = "github:clemenscodes/lanzaboote";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    pwndbg = {
      url = "github:pwndbg/pwndbg";
    };
    nix-gaming = {
      url = "github:fufexan/nix-gaming";
    };
    lsfg-vk-flake.url = "github:pabloaul/lsfg-vk-flake/main";
    lsfg-vk-flake.inputs.nixpkgs.follows = "nixpkgs";
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
    };
    cardanix = {
      url = "github:clemenscodes/cardanix/develop";
    };
    templates = {
      url = "github:NixOS/templates";
    };
    yubikey-guide = {
      url = "github:drduh/YubiKey-Guide";
      flake = false;
    };
    chaotic = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    };
    w3c = {
      url = "github:clemenscodes/W3ChampionsOnLinux";
    };
    mtkbt = {
      url = "github:clemenscodes/linux-mediatek-mt6639-bluetooth-kernel-module";
    };
  };
  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    inherit (pkgs) lib;
    system = "x86_64-linux";
    overlays = import ./overlays {inherit inputs pkgs lib;};
    pkgs = import nixpkgs {
      inherit system overlays;
      config = {
        allowUnfreePredicate = pkg:
          builtins.elem (lib.getName pkg) [
            "nvidia-x11"
            "nvidia-settings"
            "nvidia-persistenced"
          ];
      };
    };
  in {
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
