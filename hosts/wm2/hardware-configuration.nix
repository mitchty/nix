# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usbhid" "usb_storage" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
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

  fileSystems."/efiboot/efi0" =
    {
      device = "/dev/disk/by-uuid/AA22-C404";
      fsType = "vfat";
    };

  fileSystems."/efiboot/efi1" =
    {
      device = "/dev/disk/by-uuid/AA22-F2B0";
      fsType = "vfat";
    };

  swapDevices =
    [{
      device = "/dev/disk/by-label/SWAPMD";
      #      randomEncryption = true;
    }];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp103s0f4u1c2.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp2s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
