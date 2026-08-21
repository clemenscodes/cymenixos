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
  # lib.mergeAttrs merges one level deep, and two of the paths above share the
  # attribute xdg, so folding with it kept only the last of them. The mutable
  # option was therefore never declared on xdg.configFile, and setting it there
  # failed with an error about an option that does not exist. Only home.file and
  # xdg.dataFile ever had it, which is why this went unnoticed for so long.
  mergeAttrsList = builtins.foldl' lib.recursiveUpdate {};
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
  # Every file that asked to be mutable, which is the list both activation
  # entries below work from.
  #
  # home.file alone, even though mutable can be set on the xdg options as well.
  # Home manager folds xdg.configFile and xdg.dataFile into home.file
  # unconditionally, so home.file is already the complete list, and reading the
  # xdg options on top would name those files a second time.
  mutableFiles = let
    allFiles = builtins.attrValues config.home.file;
    filterMutableFiles = builtins.filter (file:
      (file.mutable or false)
      && lib.assertMsg file.force
      "if you specify `mutable` to `true` on a file, you must also set `force` to `true`");
  in
    filterMutableFiles allFiles;
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
        # Every mutable target taken away before home manager links, and this is
        # what keeps a .home-manager-backup from being written beside every one
        # of them at every single switch.
        #
        # A mutable file is a real file by the time the next activation runs,
        # because the copy below made it one and the program it belongs to has
        # been writing to it since. Home manager sorts a target that exists and
        # is not a symlink onto its slow path, and that path moves the target to
        # $target.$HOME_MANAGER_BACKUP_EXT before it does anything else. It does
        # that BEFORE it compares the contents, so it happens whether or not
        # anything changed, and backupFileExtension is set for this whole
        # configuration. force does not help, it only takes away the collision
        # check that runs earlier, in checkLinkTargets.
        #
        # So every mutable file left one saved copy beside itself after every
        # switch, forever. Taken away here instead, the target is simply missing
        # when home manager gets there, it takes the fast path and writes its
        # link with nothing to back up.
        #
        # Nothing that was meant to be kept is lost. What a mutable file should
        # contain is what is declared, the copy below puts exactly that back a
        # moment later, and a file whose runtime state is worth keeping is a file
        # that should not have been declared mutable.
        #
        # entryBetween and not entryBefore, so this lands after the write
        # boundary as well. Everything before that boundary is supposed to touch
        # nothing, and this removes files.
        mutableFileCleanup = let
          toCommand = file: ''
            $DRY_RUN_CMD rm -f $VERBOSE_ARG ${lib.escapeShellArg file.target}
          '';
          command =
            ''
              echo "Removing mutable home files before linking for $HOME"
            ''
            + lib.concatLines (map toCommand mutableFiles);
        in (inputs.home-manager.lib.hm.dag.entryBetween ["linkGeneration"] ["writeBoundary"] command);
        mutableFileGeneration = let
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
