# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "uhci_hcd" "hpsa" "usbhid" "usb_storage" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "zroot/os/root";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    {
      device = "zroot/os/nix";
      fsType = "zfs";
    };

  fileSystems."/var" =
    {
      device = "zroot/os/var";
      fsType = "zfs";
    };

  fileSystems."/home" =
    {
      device = "zroot/user/home";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/8CF0-F8BC";
      fsType = "vfat";
    };

  fileSystems."/boot1" =
    {
      device = "/dev/disk/by-uuid/8CF1-AAC5";
      fsType = "vfat";
    };

  fileSystems."/boot2" =
    {
      device = "/dev/disk/by-uuid/8CF2-1612";
      fsType = "vfat";
    };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/afe341bc-0bed-45ac-b241-770073262668"; }];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno1.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno2.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno3.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno4.useDHCP = lib.mkDefault true;

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
