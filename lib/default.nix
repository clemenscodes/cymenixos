{lib, ...}:
lib
// {
  mkModuleOption = import ./mkModuleOption {inherit lib;};
  moduleCfg = import ./moduleCfg;
}
