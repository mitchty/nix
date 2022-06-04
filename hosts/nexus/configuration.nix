{ config, ... }: {
  imports =
    [
      ./..

      # Ordering of imports is for understanding not alphanumeric sorted
      ./hardware-configuration.nix
      ../pipewire.nix
      ../virtualization.nix
      ../binfmt.nix
      ../desktop.nix
      ../zfs.nix
      ../userscompat.nix
    ];

  # This config is for nixos release 21.11
  config.system.stateVersion = "21.11";

  # This is an intel system, do "intel" stuff to it
  config.services.role.intel.enable = true;

  # We want gui stuff here
  config.services.role.gui.enable = true;

  # Play the part of a dns server for a bit...
  config.services.role.dns = {
    enable = true;
  };

  # Due to ^^^ we're setting our ip statically
  config = {
    networking = {
      hostName = "nexus";
      hostId = "30d18215";
      defaultGateway = "10.10.10.1";
      interfaces.eno1.ipv4.addresses = [{ address = "10.10.10.2"; prefixLength = 24; }];
      interfaces.eno1.useDHCP = false;
      # Use internal dnsmasq by default, has all the dns blacklists and stuff,
      # should be the fastest as well as its local network.
      nameservers = [ "127.0.0.1" "1.1.1.1" "8.8.8.8" ];
    };
  };
}
