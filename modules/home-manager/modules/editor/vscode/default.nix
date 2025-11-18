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

  vscodeCfg = config.programs.vscode;

  vscodePname = vscodeCfg.package.pname;

  configDir =
    {
      "vscode" = "Code";
      "vscode-insiders" = "Code - Insiders";
      "vscodium" = "VSCodium";
    }.${
      vscodePname
    };

  userDir = "${config.xdg.configHome}/${configDir}/User";
  configFilePath = "${userDir}/settings.json";
  tasksFilePath = "${userDir}/tasks.json";
  keybindingsFilePath = "${userDir}/keybindings.json";
  snippetDir = "${userDir}/snippets";
  pathsToMakeWritable = lib.flatten [
    (lib.optional (cfg.profiles.default.userTasks != {}) tasksFilePath)
    (lib.optional (cfg.profiles.default.userSettings != {}) configFilePath)
    (lib.optional (cfg.profiles.default.keybindings != []) keybindingsFilePath)
    (lib.optional (cfg.profiles.default.globalSnippets != {})
      "${snippetDir}/global.code-snippets")
    (lib.mapAttrsToList (language: _: "${snippetDir}/${language}.json")
      cfg.profiles.default.languageSnippets)
  ];
in {
  imports = [
    (import ./keybindings.nix {inherit inputs pkgs lib;})
    (import ./settings.nix {inherit inputs pkgs lib;})
    (import ./extensions.nix {inherit inputs pkgs lib;})
    (import ./launcher.nix {inherit inputs pkgs lib;})
    (import (builtins.fetchurl {
      url = "https://gist.githubusercontent.com/piousdeer/b29c272eaeba398b864da6abf6cb5daa/raw/41e569ba110eb6ebbb463a6b1f5d9fe4f9e82375/mutability.nix";
      sha256 = "4b5ca670c1ac865927e98ac5bf5c131eca46cc20abf0bd0612db955bfc979de8";
    }) {inherit config lib;})
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
      file =
        lib.genAttrs pathsToMakeWritable (_: {
          force = true;
          mutable = true;
        })
        // {
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
