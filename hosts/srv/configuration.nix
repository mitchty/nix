{ config, pkgs, ... }: {
  imports = [
    ./..
    ./hardware-configuration.nix
    ../kernel.nix
    ../virtualization.nix
    ../binfmt.nix
    ../desktop.nix
    ../zfs-grub.nix
    ../userscompat.nix
  ];

  config = {
    system.stateVersion = "22.05";

    services.zfs.autoScrub.enable = true;

    networking = {
      hostName = "srv";
      hostId = "81297957";

      firewall = {
        enable = true;
        trustedInterfaces = [ "eno1" ];
        interfaces = {
          "eno1" = {
            allowedTCPPorts = [ 22 9002 ];
            allowedUDPPorts = [ ];
          };
        };
      };
      interfaces = {
        eno1.useDHCP = true;
        eno2.useDHCP = true;
        eno3.useDHCP = true;
        eno4.useDHCP = true;
      };
    };
    boot.loader.grub.mirroredBoots = [
      { devices = [ "nodev" ]; path = "/boot"; }
      { devices = [ "nodev" ]; path = "/boot1"; }
      { devices = [ "nodev" ]; path = "/boot2"; }
    ];
  };
}
