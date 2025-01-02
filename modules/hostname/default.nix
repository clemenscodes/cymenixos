{lib, ...}: {...}: {
  options = {
    modules = {
      hostname = {
        enable = lib.mkEnableOption "Enable hostname" // {default = false;};
        defaultHostname = lib.mkOption {
          type = lib.types.str;
          default = "cymenix";
        };
      };
    };
  };
}
