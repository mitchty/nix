{ config, device, lib, ... }: {
  # TODO, use new GPT layout https://github.com/nix-community/disko/blob/master/example/simple-efi.nix
  networking.hostId = lib.mkForce "00000000";
  services.zfs.autoScrub.enable = lib.mkForce true;
  boot = {
    kernelPackages = lib.mkForce config.boot.zfs.package.latestCompatibleLinuxPackages;
    supportedFilesystems = [ "zfs" ];
    zfs.forceImportAll = lib.mkForce true;
  };
  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "uas" ];
  disko.devices = {
    disk = {
      disk1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00001";
        #        inherit device;
        content = {
          type = "table";
          format = "gpt";
          partitions = [
            {
              name = "boot";
              start = "0";
              end = "1M";
              part-type = "primary";
              flags = [ "bios_grub" ];
            }
            {
              name = "ESP";
              start = "1M";
              end = "1G";
              bootable = true;
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            }
            {
              name = "zfsroot";
              start = "1G";
              end = "100%";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            }
          ];
        };
      };
    };
    zpool = {
      rpool = {
        type = "zpool";
        rootFsOptions = {
          acltype = "posixacl";
          compression = "zstd";
          dnodesize = "auto";
          normalization = "formD";
          relatime = "on";
          xattr = "sa";
        };
        options = {
          ashift = "12";
          autotrim = "on";
        };

        datasets = {
          "root" = {
            type = "zfs_fs";
            options = {
              mountpoint = "legacy";
            };
            mountpoint = "/";
          };
          "nix" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/nix";
          };
          "var" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/var";
          };
          "persist" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/persist";
          };
          "home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            options.mountpoint = "legacy";
          };
        };
      };
    };
  };
}
