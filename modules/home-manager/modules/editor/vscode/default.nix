{
  inputs,
  lib,
  ...
}: {
  config,
  osConfig,
  system,
  ...
}: let
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          "vscode"
          "vscode-extension-fill-labs-dependi"
          "vscode-extension-ms-vscode-remote-remote-containers"
          "vscode-extension-ms-vscode-remote-remote-wsl"
          "vscode-extension-ms-vscode-remote-remote-ssh-edit"
        ];
    };
    overlays = [inputs.nix-vscode-extensions.overlays.default];
  };
  codevim = pkgs.writeShellScriptBin "codevim" ''
    nix run github:clemenscodes/codevim -- "$@"
  '';
  cfg = config.modules.editor;
in {
  imports = [
    (import ./keybindings.nix {inherit inputs pkgs lib;})
    (import ./settings.nix {inherit inputs pkgs lib;})
    (import ./extensions.nix {inherit inputs pkgs lib;})
    (import ./launcher.nix {inherit inputs pkgs lib;})
  ];
  options = {
    modules = {
      editor = {
        vscode = {
          enable = lib.mkEnableOption "Enable VSCode" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.vscode.enable) {
    home = {
      file = {
        ".config/nvim/init.vscode.lua" = {
          text = ''
            if vim.g.vscode then
                -- VSCode extension
            else
                -- ordinary Neovim
            end
          '';
        };
      };
      activation = {
        makeVSCodeConfigWritable = let
          configDirName =
            {
              "vscode" = "Code";
              "vscode-insiders" = "Code - Insiders";
              "vscodium" = "VSCodium";
            }.${
              config.programs.vscode.package.pname
            };
          configPath = "${config.xdg.configHome}/${configDirName}/User/settings.json";
        in {
          after = ["writeBoundary"];
          before = [];
          data = ''
            install -m 0640 "$(readlink ${configPath})" ${configPath}
          '';
        };
      };
      packages = [codevim];
      persistence = lib.mkIf osConfig.modules.boot.enable {
        "${osConfig.modules.boot.impermanence.persistPath}${config.home.homeDirectory}" = {
          directories = [
            ".vscode"
            ".config/Code"
          ];
        };
      };
    };
    programs = {
      vscode = {
        enable = true;
        package = pkgs.vscode;
      };
    };
  };
}
