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
  };

  # This is an intel system, do "intel" stuff to it
  config.services.role.intel.enable = true;

  # Tag this system as a low memory system
  config.services.role.lowmem.enable = true;
}
