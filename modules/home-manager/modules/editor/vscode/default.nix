{
  inputs,
  lib,
  pkgs,
  ...
}: {
  config,
  osConfig,
  ...
}: let
  codevim = pkgs.writeShellScriptBin "codevim" ''
    exec ${pkgs.neovim}/bin/nvim "$@"
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
    (lib.optional (vscodeCfg.profiles.default.userTasks != {}) tasksFilePath)
    (lib.optional (vscodeCfg.profiles.default.userSettings != {}) configFilePath)
    (lib.optional (vscodeCfg.profiles.default.keybindings != []) keybindingsFilePath)
    (lib.optional (vscodeCfg.profiles.default.globalSnippets != {})
      "${snippetDir}/global.code-snippets")
    (lib.mapAttrsToList (language: _: "${snippetDir}/${language}.json")
      vscodeCfg.profiles.default.languageSnippets)
  ];
in {
  imports = [
    (import ./keybindings.nix {inherit inputs pkgs lib;})
    (import ./settings.nix {inherit inputs pkgs lib;})
    (import ./extensions.nix {inherit inputs pkgs lib;})
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
      # VSCode has no setting for the activity bar order, it lives in its state database
      # as the position in this array, the order fields are overwritten by the extensions.
      # Takes effect when VSCode is closed during activation, a running instance overwrites it on exit.
      activation.vscodeActivityBarOrder = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
        db="${userDir}/globalStorage/state.vscdb"
        key="workbench.activity.pinnedViewlets2"
        if [ -f "$db" ]; then
          current=$(${pkgs.sqlite}/bin/sqlite3 "$db" "select value from ItemTable where key = '$key';")
          if [ -n "$current" ]; then
            updated=$(printf '%s' "$current" | ${pkgs.jq}/bin/jq -c '
              ["workbench.view.explorer",
               "workbench.view.search",
               "workbench.view.extension.test",
               "workbench.view.debug",
               "workbench.view.scm",
               "workbench.view.extension.containersView",
               "workbench.view.extension.dockerView"] as $first
              | sort_by(.id as $id
                  | ($first | index($id)) as $i
                  | if $i != null then $i
                    elif $id == "workbench.view.extension.moonConsole" then 998
                    elif $id == "workbench.view.extensions" then 999
                    else 100
                    end)')
            run ${pkgs.sqlite}/bin/sqlite3 "$db" "update ItemTable set value = '$updated' where key = '$key';"
          fi
        fi
      '';
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
        "${osConfig.modules.boot.impermanence.persistPath}" = {
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
