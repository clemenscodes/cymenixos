# CYMENIXOS

This flake exposes NixOS modules for general use cases.

It provides a full system with sane default options.

## Usage

A minimal example in a `flake.nix`

```nix
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
    cymenixos,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    inherit (pkgs) lib;
  in {
    nixosConfigurations = {
      cymenixos = lib.nixosSystem {
        specialArgs = {inherit self inputs pkgs nixpkgs system;};
        modules = [
          cymenixos.nixosModules.${system}.default
          ({...}: {
            # additional configuration
          })
        ];
      };
    };
  };
}
```

## Software used

- Kernel: `latest`
- Terminal: `kitty`
- Shell: `zsh`
- Prompt: `starship`
- Email Client: `neomutt`
- Text Editor: `nvim`
- Display Server: `wayland`
- Display Manager: `sddm`
- Compositor: `hyprland`
- App Launcher: `rofi`
- Status Bar: `waybar`
- File Browser: `lf`
- Browser: `firefox`
- PDF Viewer: `zathura`
- Notification Center: `swaynotificationcenter`
- Music Player: `mpd`
- Music Player Frontend: `ncmpcpp`
- Video Player: `mpv`
- Bootloader: `grub`
- Process Manager: `btop`
- Password Manager: `bitwarden`
- Font: `iosevka`
- Wallpaper Engine: `swww`
- Powermenu: `wlogout`
- Theme: `Catppuccin Macchiato Blue`

## Documentation

Work in progress...

Currently all custom options are namespaced under the `modules` option.

Options are defined according to the directory structure.

To tweak options, take a look at the [modules](./modules/)

Feel free to reach out if you have any questions.
