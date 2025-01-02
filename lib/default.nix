{lib, ...}: {
  mkModule = import ./mkModule {inherit lib;};
  mkSubModule = import ./mkSubModule {inherit lib;};
  moduleCfg = import ./moduleCfg;
}
