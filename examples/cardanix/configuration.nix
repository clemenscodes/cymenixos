{
  inputs,
  system,
  ...
}: {
  imports = [inputs.cymenixos.nixosModules.${system}.default];
  modules = {
    enable = true;
    config = {
      enable = true;
    };
    disk = {
      enable = true;
      device = "/dev/sda";
    };
    crypto = {
      enable = true;
      cardanix = {
        enable = true;
      };
    };
  };
}
