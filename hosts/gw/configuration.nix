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

        # This is my router too
        router.enable = true;
      };
    };

    # Generated stuff goes here...
    networking = {
      hostName = "gw";
      hostId = "89fdcfd5";
    };
    boot.loader.grub.mirroredBoots = [
      { devices = [ "nodev" ]; path = "/boot"; }
    ];
  };
}
