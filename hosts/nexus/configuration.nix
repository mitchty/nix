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
  config.services = {
    role.intel.enable = true;
    role.gui.enable = true;
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

  # Due to ^^^ we're setting our ip statically
  config = {
    networking = {
      hostName = "nexus";
      hostId = "30d18215";
    };
    networking.firewall = {
      enable = true;
      trustedInterfaces = [ "eno1" ];

      interfaces = {
        "enp3s0f3" = {
          allowedTCPPorts = [ 22 9002 ];
          allowedUDPPorts = [ ];
        };
      };
    };
  };
}
