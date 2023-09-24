{ config, ... }: {
  imports =
    [
      ./..
      ./hardware-configuration.nix
      ../kernel.nix
      ../virtualization.nix
      ../zfs-grub.nix
      ../userscompat.nix
    ];
  config = {
    system.stateVersion = "22.11";
    services = {
      zfs.autoScrub.enable = true;
    };
    boot.loader.grub.mirroredBoots = [
      { devices = [ "nodev" ]; path = "/boot"; }
      { devices = [ "nodev" ]; path = "/boot1"; }
    ];
    networking = {
      hostName = "cl2";
      hostId = "b3dca20b";

      vlans = {
        vlan100 = { id = 100; interface = "enp1s0"; };
        vlan101 = { id = 101; interface = "enp2s0"; };
      };

      interfaces = {
        enp1s0.useDHCP = true;
        # The interface will have a rfc1918 address separate from the vlan
        # tagged ip.
        enp2s0.ipv4.addresses = [{
          address = "192.168.254.2";
          prefixLength = 29;
        }];
        vlan100.ipv4.addresses = [{
          address = "10.254.128.2";
          prefixLength = 29;
        }];
        vlan101.ipv4.addresses = [{
          address = "10.254.254.2";
          prefixLength = 29;
        }];
      };
    };
  };
}
