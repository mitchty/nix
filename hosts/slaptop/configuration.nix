{ config, pkgs, lib, ... }: {
  imports =
    [
      ./..

      # Ordering of imports is for understanding not alphanumeric sorted
      ./hardware-configuration.nix
      ../pipewire.nix
      ../virtualization.nix
      ../binfmt.nix
      ../laptop.nix
    ];

  config = {
    # Non dhcp hostname
    networking.hostName = "slaptop";

    # This config is for nixos release 21.11
    system.stateVersion = "21.11";

    services.role = {
      intel.enable = true;
      gui.enable = true;
      vpn.enable = true;
    };

    # Use the latest packaged kernel rev
    boot.kernelPackages = pkgs.linuxPackages_latest;

    # Luks specific to this node
    boot.loader.grub.enableCryptodisk = true;

    boot.loader.grub.devices = [ "/dev/disk/by-uuid/5996-2431" ];

    boot.initrd.luks.devices = {
      crypted = {
        device = "/dev/disk/by-uuid/fdd79b6e-151d-476e-aa88-c6f1f2de3fe5";
        preLVM = true;
      };
    };
  };
}
