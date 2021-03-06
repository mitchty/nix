{ config, ... }: {
  boot.loader = {
    grub = {
      efiSupport = true;
      device = "nodev";
    };
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.supportedFilesystems = [ "zfs" ];
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.devNodes = "/dev/disk/by-partuuid";

  # Use the latest packaged kernel rev with zfs support
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
}
