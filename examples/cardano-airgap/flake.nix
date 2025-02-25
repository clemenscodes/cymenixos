{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    cymenixos = {
      url = "github:clemenscodes/cymenixos/develop";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
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
      overlays = [] ++ inputs.cymenixos.overlays.${system}.default;
    };
    inherit (pkgs) lib;
  in {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit self inputs nixpkgs system;};
        modules = [./configuration.nix];
      };
      offline = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit self inputs nixpkgs system;};
        modules = [
          ./configuration.nix
          ({...}: {
            modules = {
              airgap = {
                offline = true;
              };
            };
          })
        ];
      };
      iso = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit self inputs nixpkgs system;};
        modules = [
          ./configuration.nix
          (import "${inputs.cymenixos}/modules/iso" {inherit inputs pkgs lib;})
          ({...}: {
            modules = {
              iso = {
                enable = true;
              };
            };
          })
        ];
      };
      offline-iso = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit self inputs nixpkgs system;};
        modules = [
          ./configuration.nix
          (import "${inputs.cymenixos}/modules/iso" {inherit inputs pkgs lib;})
          ({...}: {
            modules = {
              airgap = {
                offline = true;
              };
              iso = {
                enable = true;
              };
            };
          })
        ];
      };
      test = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit self inputs nixpkgs system;};
        modules = [
          ./configuration.nix
          (import "${inputs.cymenixos}/modules/iso" {inherit inputs pkgs lib;})
          ({...}: {
            modules = {
              iso = {
                enable = true;
                fast = true;
              };
            };
          })
        ];
      };
      offline-test = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit self inputs nixpkgs system;};
        modules = [
          ./configuration.nix
          (import "${inputs.cymenixos}/modules/iso" {inherit inputs pkgs lib;})
          ({...}: {
            modules = {
              airgap = {
                offline = true;
              };
              iso = {
                enable = true;
                fast = true;
              };
            };
          })
        ];
      };
    };
  };

  nixConfig = {
    extra-substituters = ["https://cache.iog.io"];
    extra-trusted-public-keys = ["hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="];
    allow-import-from-derivation = "true";
    experimental-features = ["nix-command" "flakes" "fetch-closure"];
  };
}
