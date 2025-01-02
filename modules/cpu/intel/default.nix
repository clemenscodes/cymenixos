{lib, ...}: {...}: {
  options = {
    modules = {
      cpu = {
        intel = {
          enable = lib.mkEnableOption "Enable Intel CPU settings" // {default = false;};
        };
      };
    };
  };
}
