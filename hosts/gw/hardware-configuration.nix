# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "usbhid" "usb_storage" "sd_mod" "sr_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/7ad6095d-e62d-4b8f-862a-a21379641be2";
      fsType = "ext3";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/1DEA-928B";
      fsType = "vfat";
    };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/3ff4a619-8aa9-4c3e-925b-07f46f4d6d94"; }];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
