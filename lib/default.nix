{
  lib,
  config,
  ...
}: {
  mkModule = import ./mkModule {inherit lib config;};
  mkSubModule = import ./mkSubModule {inherit lib config;};
  moduleCfg = import ./moduleCfg;
}
