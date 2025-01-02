{lib, ...}: {...}: {
  options = {
    modules = {
      cpu = {
        amd = {
          enable = lib.mkEnableOption "Enable AMD CPU settings" // {default = false;};
        };
      };
    };
  };
}
