# Replace pkgs.aggregateModules with a version whose postBuild tolerates missing
# external-module .ko.cer files. callPackage keeps .override intact, which
# nixos/modules/system/boot/kernel.nix relies on ((pkgs.aggregateModules modules)
# .override { name = ...-modules; }). See kmod-aggregator-fixed.nix for the why.
final: prev: {
  aggregateModules = modules: final.callPackage ./kmod-aggregator-fixed.nix {inherit modules;};
}
