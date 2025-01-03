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
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    inherit (pkgs) lib;
  in {
    nixosModules = {
      ${system} = {
        default = import ./modules {inherit inputs pkgs lib;};
      };
    };
    packages = {
      ${system} = {
        default = let
          build-system = pkgs.writeShellApplication {
            name = "build-system";
            runtimeInputs = [pkgs.nix-output-monitor];
            text = ''
              nom build .#nixosConfigurations.cymenixos.config.system.build.toplevel --show-trace
            '';
          };
          build-iso = pkgs.writeShellApplication {
            name = "build-iso";
            runtimeInputs = [pkgs.nix-output-monitor];
            text = ''
              nom build .#nixosConfigurations.cymenixos.config.system.build.isoImage --show-trace
            '';
          };
          qemu-run-iso = pkgs.writeShellApplication {
            name = "qemu-run-iso";
            runtimeInputs = with pkgs; [fd qemu_kvm pipewire pipewire.jack];

            text = ''
              if fd --type file --has-results 'nixos-.*\.iso' result/iso 2> /dev/null; then
                echo "Symlinking the existing iso image for qemu:"
                ln -sfv result/iso/nixos-*.iso result-iso
                echo
              else
                echo "No iso file exists to run, please build one first, example:"
                echo "  nix build -L .#nixosConfigurations.airgap-boot.config.system.build.isoImage"
                exit
              fi

              if [ "$#" = 0 ]; then
                echo "Not passing through any host devices; see the README.md if you would like to do that."
              fi

              # To disallow a network nic, pass: -nic none
              # See README.md for additional args to pass through a host device
              LD_LIBRARY_PATH="${pkgs.pipewire.jack}/lib" qemu-kvm \
                -smp 2 \
                -m 4G \
                -drive file=result-iso,format=raw,if=none,media=cdrom,id=drive-cd1,readonly=on \
                -device ahci,id=achi0 \
                -device ide-cd,bus=achi0.0,drive=drive-cd1,id=cd1,bootindex=1 \
                "$@"
            '';
          };
        in
          pkgs.stdenv.mkDerivation {
            name = "cymenixos-scripts";
            phases = "installPhase";
            installPhase = ''
              mkdir -p $out/bin
              ln -s ${build-system}/bin/build-system $out/bin
              ln -s ${build-iso}/bin/build-iso $out/bin
              ln -s ${qemu-run-iso}/bin/qemu-run-iso $out/bin
            '';
          };
      };
    };
    devShells = {
      ${system} = {
        default = pkgs.mkShell {
          nativeBuildInputs = [self.packages.${system}.default];
        };
      };
    };
    formatter.${system} = pkgs.alejandra;
  };
}
