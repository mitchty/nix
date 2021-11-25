{ config, pkgs, modulesPath, lib, ... }: {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules =
    [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  networking.hostId = "30d18215";

  fileSystems."/" = {
    device = "zroot/safe/root";
    fsType = "zfs";
  };

  fileSystems."/nix" = {
    device = "zroot/local/nix";
    fsType = "zfs";
  };

  fileSystems."/home" = {
    device = "zroot/safe/home";
    fsType = "zfs";
  };

  fileSystems."/boot" = {
    device = "/dev/nvme0n1p1";
    fsType = "vfat";
  };

  fileSystems."/boot-bk" = {
    device = "/dev/nvme1n1p1";
    fsType = "vfat";
  };

  swapDevices = [ ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  # high-resolution display
  hardware.video.hidpi.enable = lib.mkDefault true;
}
