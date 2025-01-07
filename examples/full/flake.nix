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
      overlays = [] ++ inputs.cymenixos.overlays.${system}.default;
    };
    inherit (pkgs) lib;
  in {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit self inputs nixpkgs system;};
        modules = [./configuration.nix];
      };
      iso = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit self inputs nixpkgs system;};
        modules = [
          ./configuration.nix
          (import "${inputs.cymenixos}/modules/iso" {inherit inputs lib;})
          ({...}: let
            dependencies =
              [
                self.nixosConfigurations.your-machine.config.system.build.toplevel
                self.nixosConfigurations.your-machine.config.system.build.diskoScript
                self.nixosConfigurations.your-machine.config.system.build.diskoScript.drvPath
                self.nixosConfigurations.your-machine.pkgs.stdenv.drvPath
                self.nixosConfigurations.your-machine.pkgs.perlPackages.ConfigIniFiles
                self.nixosConfigurations.your-machine.pkgs.perlPackages.FileSlurp
                (self.nixosConfigurations.your-machine.pkgs.closureInfo {rootPaths = [];}).drvPath
              ]
              ++ builtins.map (i: i.outPath) (builtins.attrValues self.inputs);
            closureInfo = pkgs.closureInfo {rootPaths = dependencies;};
          in {
            environment = {
              etc = {
                "install-closure" = {
                  source = "${closureInfo}/store-paths";
                };
              };
            };
            modules = {
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
          (import "${inputs.cymenixos}/modules/iso" {inherit inputs lib;})
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
    };
  };
}
