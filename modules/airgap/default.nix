{lib, ...}: {config, ...}: let
  cfg = config.modules;
in {
  options = {
    modules = {
      airgap = {
        enable = lib.mkEnableOption "Enable airgap mode" // {default = false;};
      };
    };
  };
  config = lib.mkIf config.modules.airgap.enable {
    hardware = {
      bluetooth = {
        enable = lib.mkForce false;
      };
    };
    networking = {
      hostName = lib.mkDefault cfg.hostname.defaultHostname;
      enableIPv6 = lib.mkForce false;
      interfaces = lib.mkForce {};
      useDHCP = lib.mkForce false;
      networkmanager = {
        enable = lib.mkForce false;
      };
      wireless = {
        enable = lib.mkForce false;
      };
    };
    services = {
      udev = {
        extraRules = ''
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="1b7c", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="2b7c", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="3b7c", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="4b7c", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="1807", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="1808", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c97", ATTRS{idProduct}=="0000", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c97", ATTRS{idProduct}=="0001", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c97", ATTRS{idProduct}=="0004", MODE="0660", TAG+="uaccess", TAG+="udev-acl"
          KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0660", GROUP="plugdev", ATTRS{idVendor}=="2c97"
          KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0660", GROUP="plugdev", ATTRS{idVendor}=="2581"
          ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="0", ATTR{authorized}="1"
        '';
      };
    };
    modules = {
      networking = {
        enable = lib.mkForce false;
      };
    };
  };
}
