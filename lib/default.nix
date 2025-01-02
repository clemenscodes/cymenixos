{lib, ...}:
lib
// {
  mkModuleOption = import ./mkModuleOption {inherit lib;};
  mkSubModuleOption = import ./mkSubModuleOption {inherit lib;};
  moduleCfg = import ./moduleCfg;
}
