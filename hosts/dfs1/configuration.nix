{ config, ... }: {
  imports =
    [
      ./..
      # ../kernel.nix
      # Ordering of imports is for understanding not alphanumeric sorted
      ./hardware-configuration.nix
      # Samba is ASS it constantly coredumps on me when I try to use it
      # ../samba.nix
      ../kernel.nix
      ../zfs-grub.nix
    ];

  config = {
    # Ok so the hardware-configuration.nix has autogenerated stuff, everything
    # here is "after install crap I define manually" regarding mount points etc...
    fileSystems = {
      "/backup" =
        {
          device = "backup";
          fsType = "zfs";
          options = [ "nofail" ];
        };
      "/srv" =
        {
          device = "test/srv";
          fsType = "zfs";
          options = [ "nofail" ];
        };
    };

    system.stateVersion = "21.11";

    services = {
      znapzend = {
        enable = true;
        autoCreation = true;
        pure = true;
        zetup."test/srv" = {
          plan = "1h=>15min,1d=>1h,1w=>1d,1m=>1w,1y=>1m";
          destinations.local = {
            dataset = "backup";
          };
        };
      };
      # TODO: Put this into some sorta common zfs module once I figure out what
      # makes sense to abstract into a module
      zfs.autoScrub.enable = true;
    };

    networking.firewall = {
      enable = true;
      trustedInterfaces = [ "enp3s0f3" ];

      interfaces = {
        "enp3s0f3" = {
          allowedTCPPorts = [ 22 9002 ];
          allowedUDPPorts = [ ];
        };
      };
    };

    # Generated stuff goes here...
    networking.hostName = "dfs1";
    networking.hostId = "23ee5d32";
    boot.loader.grub.mirroredBoots = [
      { devices = [ "nodev" ]; path = "/boot"; }
      { devices = [ "nodev" ]; path = "/boot1"; }
      { devices = [ "nodev" ]; path = "/boot2"; }
    ];
  };
}
