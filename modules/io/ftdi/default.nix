{lib, ...}: {config, ...}: let
  cfg = config.modules.io;
in {
  options = {
    modules = {
      io = {
        ftdi = {
          enable = lib.mkEnableOption "Enable user access to FTDI MPSSE USB bridges for SPI, I2C, and JTAG host tools" // {default = false;};
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable && cfg.ftdi.enable) {
    services = {
      udev = {
        # FTDI MPSSE USB bridges, host tool access for SPI, I2C, and JTAG without root.
        # Used by the vanix external SPI TPM read path over an FT232H bridge so tpm2 can
        # open the device. FT2232H 6010, FT4232H 6011, FT232H 6014.
        extraRules = ''
          SUBSYSTEM=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="0666"
          SUBSYSTEM=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6011", MODE="0666"
          SUBSYSTEM=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6014", MODE="0666"
        '';
      };
    };
  };
}
