{ config, ... }: {
  imports = [
    ./..
    ./hardware-configuration.nix
  ];

  config = {

    system.stateVersion = "22.05";

    services = {
      role = {
        # This is an intel system, do "intel" stuff to it
        intel.enable = true;
      };
    };

    # Generated stuff goes here...
    networking.hostName = "gw";
    networking.hostId = "89fdcfd5";
    networking.interfaces.eno1.useDHCP = true;
    boot.loader.grub.mirroredBoots = [
      { devices = [ "nodev" ]; path = "/boot"; }
    ];
  };
}
