{ config, pkgs, ... }: {
  imports = [
    ./..
    ./hardware-configuration.nix
    ../virtualization.nix
    ../binfmt.nix
    ../desktop.nix
    ../zfs-grub.nix
    ../userscompat.nix
  ];

  config = {
    system.stateVersion = "22.05";

    services = {
      role = {
        intel.enable = true;
        gui.enable = true;
        promtail.enable = true;
        nixcache.enable = true;
      };
      prometheus = {
        exporters = {
          node = {
            enable = true;
            enabledCollectors = [ "systemd" ];
            port = 9002;
          };
        };
      };
    };

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
