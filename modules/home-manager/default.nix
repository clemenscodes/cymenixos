{
  inputs,
  pkgs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.modules;
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
  imports = [inputs.home-manager.nixosModules.home-manager];
  options =
    {
      modules = {
        home-manager = {
          enable = lib.mkEnableOption "Enable home-manager" // {default = false;};
        };
      };
    }
    // mergeAttrsList (map (attrPath:
      lib.setAttrByPath attrPath (lib.mkOption {type = fileAttrsType;}))
    fileOptionAttrPaths);

  config = {
    system = {
      stateVersion = lib.mkDefault (lib.versions.majorMinor lib.version);
    };
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = {inherit inputs pkgs system;};
      backupFileExtension = "home-manager-backup";
      users = {
        ${cfg.users.user} = {
          imports = [(import ./modules {inherit inputs pkgs lib;})];
          home = {
            stateVersion = lib.mkDefault (lib.versions.majorMinor lib.version);
          };
        };
      };
      activation = {
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
    };
  };
}
