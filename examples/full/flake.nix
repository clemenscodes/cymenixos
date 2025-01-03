{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    cymenixos = {
      url = "github:clemenscodes/cymenixos";
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
    };
    inherit (pkgs) lib;
  in {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit self inputs pkgs lib nixpkgs system;};
        modules = [./configuration.nix];
      };
      iso = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit self inputs pkgs lib nixpkgs system;};
        modules = [
          ./configuration.nix
          ({modulesPath, ...}: {
            imports = [(modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")];
            modules = {
              disk = {
                enable = lib.mkForce false;
              };
            };
          })
        ];
      };
    };
  };
}
