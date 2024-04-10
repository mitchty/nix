{ device
, lib
, ...
}: {
  # TODO, use new GPT layout https://github.com/nix-community/disko/blob/master/example/simple-efi.nix
  networking.hostId = lib.mkForce "00000000";
  services.zfs.autoScrub.enable = lib.mkForce true;
  boot = {
    #    kernelPackages = lib.mkForce config.boot.zfs.package.latestCompatibleLinuxPackages;
    supportedFilesystems = [ "vfat" ];
    #    zfs.forceImportAll = lib.mkForce true;
  };
  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "uas" ];
  disko.devices = {
    vdb = {
      inherit device;
      # device = "/dev/disk/by-id/some-disk-id";
      #   device = "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00001";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            type = "EF00";
            size = "500M";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
