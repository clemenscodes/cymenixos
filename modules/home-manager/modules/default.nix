{
  inputs,
  pkgs,
  lib,
  ...
}: {
  osConfig,
  config,
  ...
}: let
  cfg = config.modules;
  osCfg = osConfig.modules.home-manager;
  user = osConfig.modules.users.user;
  fileOptionAttrPaths = [["home" "file"] ["xdg" "configFile"] ["xdg" "dataFile"]];
  mergeAttrsList = builtins.foldl' (lib.mergeAttrs) {};
  fileAttrsType = lib.types.attrsOf (lib.types.submodule ({config, ...}: {
    options.mutable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to copy the file without the read-only attribute instead of
        symlinking. If you set this to `true`, you must also set `force` to
        `true`. Mutable files are not removed when you remove them from your
        configuration.
        This option is useful for programs that don't have a very good
        support for read-only configurations.
      '';
    };
  }));
in {
  imports = [
    (import ./browser {inherit inputs pkgs lib;})
    (import ./development {inherit inputs pkgs lib;})
    (import ./display {inherit inputs pkgs lib;})
    (import ./editor {inherit inputs pkgs lib;})
    (import ./explorer {inherit inputs pkgs lib;})
    (import ./fonts {inherit inputs pkgs lib;})
    (import ./media {inherit inputs pkgs lib;})
    (import ./monitoring {inherit inputs pkgs lib;})
    (import ./networking {inherit inputs pkgs lib;})
    (import ./operations {inherit inputs pkgs lib;})
    (import ./organization {inherit inputs pkgs lib;})
    (import ./security {inherit inputs pkgs lib;})
    (import ./shell {inherit inputs pkgs lib;})
    (import ./storage {inherit inputs pkgs lib;})
    (import ./terminal {inherit inputs pkgs lib;})
    (import ./utils {inherit inputs pkgs lib;})
    (import ./xdg {inherit inputs pkgs lib;})
  ];
  options =
    {
      modules = {
        enable = lib.mkEnableOption "Enable home-manager modules" // {default = false;};
      };
    }
    // mergeAttrsList (map (attrPath:
      lib.setAttrByPath attrPath (lib.mkOption {type = fileAttrsType;}))
    fileOptionAttrPaths);
  config = lib.mkIf (cfg.enable && osCfg.enable) {
    programs = {
      home-manager = {
        inherit (cfg) enable;
      };
    };
    home = {
      persistence = lib.mkIf osConfig.modules.boot.enable {
        "${osConfig.modules.boot.impermanence.persistPath}" = {
          directories = [
            ".local/src"
            ".local/bin"
            ".local/share/keyrings"
            (lib.mkIf (osConfig.modules.gaming.enable && osConfig.modules.gaming.steam.enable) {
              directory = ".local/share/Steam";
              method = "symlink";
            })
          ];
        };
      };
      keyboard = {
        layout = osConfig.modules.locale.defaultLocale;
      };
      username = user;
      homeDirectory = "/home/${user}";
      sessionPath = ["${config.home.homeDirectory}/.local/bin"];
      extraOutputsToInstall = ["doc" "info" "devdoc"];
      preferXdgDirectories = true;
      activation = {
        rmUnusedNix = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
          rm -rf ${config.home.homeDirectory}/.nix-defexpr
          rm -rf ${config.home.homeDirectory}/.nix-profile
        '';
        mutableFileGeneration = let
          allFiles = builtins.concatLists (map
            (attrPath: builtins.attrValues (lib.getAttrFromPath attrPath config))
            fileOptionAttrPaths);
          filterMutableFiles = builtins.filter (file:
            (file.mutable or false)
            && lib.assertMsg file.force
            "if you specify `mutable` to `true` on a file, you must also set `force` to `true`");
          mutableFiles = filterMutableFiles allFiles;
          toCommand = file: let
            source = lib.escapeShellArg file.source;
            target = lib.escapeShellArg file.target;
          in ''
            $VERBOSE_ECHO "${source} -> ${target}"
            $DRY_RUN_CMD cp --remove-destination --no-preserve=mode ${source} ${target}
          '';
          command =
            ''
              echo "Copying mutable home files for $HOME"
            ''
            + lib.concatLines (map toCommand mutableFiles);
        in (inputs.home-manager.lib.hm.dag.entryAfter ["linkGeneration"] command);
      };
      file = {
        ".local/src/README.md" = {
          text = ''
            # Source Code / Packages

            - This is the home for all external source code and projects
            - run `rr` to cd into this directory
          '';
        };
      };
    };
  };
}
