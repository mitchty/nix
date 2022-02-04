{ config, pkgs, lib, ... }: {
  imports =
    [
      ./..
      ../kernel.nix
      # Ordering of imports is for understanding not alphanumeric sorted
      ./hardware-configuration.nix
      # Samba is ASS it constantly coredumps on me when I try to use it
      # ../samba.nix
    ];

  config = {
    system.stateVersion = "21.11";

    services.rsnapshot = {
      enable = true;
      extraConfig = ''
        snapshot_root	/backup
        backup	/mnt/	local/
        retain	hourly	24
        retain	daily	31
      '';
      cronIntervals = {
        hourly = "35 1,5,9,12 * * *";
        daily = "10 0 * * *";
      };
    };
    networking.hostName = "dfs1";
    networking.hostId = "6d0ad4b7";

    # Both of these are the external ssd drives in an md array
    boot.loader.grub.mirroredBoots = [
      { devices = [ "nodev" ]; path = "/boot1"; }
      { devices = [ "nodev" ]; path = "/boot2"; }
    ];

    # Ok so the hardware-configuration.nix has autogenerated stuff, everything
    # here is "after install crap I define manually" regarding mount points etc...
    fileSystems."/backup" =
      {
        device = "/dev/disk/by-id/ata-ST18000NM000J-2TV103_ZR52YB6X";
        fsType = "xfs";
        options = [ "nofail" ];
      };

    # Cache lvm setup, created via (ignoring the md setup cause its whatever but
    # basically just using the final partition for metadata/cache purposes on
    # the / ssds):
    # md123 is the spinning rust raid 0 (yeah its a test setup for now to see if it works not be "right")
    # md126 is the ssd raid 1 for metadata/cache
    # vgcreate test /dev/md123
    # lvcreate -n test -L14TB test /dev/md123
    # vgextend test /dev/md126
    # lvcreate -n metadata -L 1GB test /dev/md126
    # lvcreate -n cache -L 670GB test /dev/md126
    # lvconvert --verbose --type cache-pool --poolmetadata test/metadata test/cache
    # lvconvert --type cache --cachepool test/cache test/test
    # mkfs.xfs /dev/mapper/test-test
    #
    # Future me figure out a way to script/automate this setup if its missing somehow.
    boot.initrd.kernelModules = [ "dm-thin-pool" "dm-cache" ];
    boot.kernelModules = [ "dm-thin-pool" "dm-cache" ];

    services.lvm.boot.thin.enable = true;

    # TODO: why do I need to run lvchange -ay test/test?
    systemd = {
      services = {
        hack = {
          enable = true;
          description = "dm-cache hack";
          serviceConfig = {
            ExecStart =
              let
                script = pkgs.writeScript "hack" ''
                  #!${pkgs.runtimeShell}
                  ${pkgs.lvm2.bin}/bin/lvchange -ay test/test
                '';
              in
              "${script} %u";
          };
          wantedBy = [ "local-fs.target" ];
        };
      };
      mounts = [
        {
          after = [ "hack.service" ];
          what = "/dev/mapper/test-test";
          where = "/mnt";
          type = "xfs";
          options = "defaults";
          wantedBy = [ "local-fs.target" ];
        }
      ];
    };
  };

  # TODO: Once I figure out how to not have to run lvchange on the cache lvm
  # volume. I hate debugging initramfs bs.
  #
  # fileSystems."/mnt" =
  #   {
  #     device = "/dev/mapper/test-test";
  #     fsType = "xfs";
  #     options = [ "nofail" ];
  #   };

  # This is an intel system, do "intel" stuff to it
  config.services.role.intel.enable = true;

  # Tag this system as a low memory system
  config.services.role.lowmem.enable = true;
}
