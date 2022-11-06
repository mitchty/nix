{ config, pkgs, ... }: {
  imports = [
    ./..
    ./hardware-configuration.nix
    ../kernel.nix
  ];

  config = {
    system.stateVersion = "22.05";

    boot.kernelPackages = pkgs.linuxPackages_latest;
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
