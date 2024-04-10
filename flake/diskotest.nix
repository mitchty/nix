{
  disko.devices.disk = {
    vdb = {
      # inherit device;
      # device = "/dev/disk/by-id/some-disk-id";
      device = "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00001";
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
              mountpoint = "/boot/efi";
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
