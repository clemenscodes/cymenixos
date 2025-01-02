{
  inputs,
  system,
  ...
}: {
  imports = [inputs.cymenixos.nixosModules.${system}.default];
  modules = {
    enable = true;
    disk = {
      enable = true;
      device = "/dev/sda";
    };
    config = {
      enable = true;
    };
    users = {
      enable = true;
    };
    crypto = {
      enable = true;
      cardanix = {
        enable = true;
      };
    };
  };
}
