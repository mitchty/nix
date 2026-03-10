{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.diskConfig.disks = lib.mkOption {
    type = lib.types.listOf lib.types.str;
  };

  config = {
    systemd.services."mdmonitor".environment = {
      MDADM_MONITOR_ARGS = "--scan --syslog";
    };

    # Shut up the silly warning, idgaf if mdadm can't email me
    boot.swraid.mdadmConf = "PROGRAM ${pkgs.coreutils}/bin/true";

    disko.devices = {
      disk = {
        prime = {
          type = "disk";
          device = builtins.elemAt config.diskConfig.disks 0;
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                priority = 1;
                name = "ESP";
                start = "1M";
                end = "1024M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [
                    "umask=0077"
                    "nofail"
                  ];
                };
              };
              mdadm = {
                size = "100%";
                content = {
                  type = "mdraid";
                  name = "raid1";
                };
              };
            };
          };
        };
        m0 = {
          type = "disk";
          device = builtins.elemAt config.diskConfig.disks 1;
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                priority = 1;
                name = "ESP";
                start = "1M";
                end = "1024M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot1";
                  mountOptions = [
                    "umask=0077"
                    "nofail"
                  ];
                };
              };
              mdadm = {
                size = "100%";
                content = {
                  type = "mdraid";
                  name = "raid1";
                };
              };
            };
          };
        };
      };
      mdadm = {
        raid1 = {
          type = "mdadm";
          level = 1;
          content = {
            type = "gpt";
            partitions = {
              root = {
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ]; # Override existing partition
                  # Subvolumes must set a mountpoint in order to be mounted,
                  # unless their parent is mounted
                  subvolumes = {
                    # Subvolume name is different from mountpoint
                    "/rootfs" = {
                      mountpoint = "/";
                    };

                    # Parent is not mounted so the mountpoint must be set
                    "/nix" = {
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                      mountpoint = "/nix";
                    };

                    # Want to have /var separate
                    "/var" = {
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                      mountpoint = "/var";
                    };

                    # lib and log are their own volumes too
                    "/var/lib" = {
                      mountOptions = [
                        "compress=zstd"
                      ];
                      mountpoint = "/var/lib";
                    };

                    # Subvolume name is the same as the mountpoint
                    "/Users" = {
                      mountOptions = [
                        "compress=zstd"
                        "users"
                      ];
                      mountpoint = "/Users";
                    };

                    # Specify the subvolume mountpoints so we can set mountOptions
                    "/Users/mitch" = {
                      mountOptions = [
                        "users"
                        "exec"
                      ];
                      mountpoint = "/Users/mitch";
                    };
                    # I keep a lot of source here
                    "/Users/mitch/src" = {
                      mountOptions = [
                        "compress=zstd"
                        "users"
                        "exec"
                      ];
                      mountpoint = "/Users/mitch/src";
                    };

                    # Subvolume for the swapfile
                    "/swap" = {
                      mountpoint = "/.swapvol";
                      swap = {
                        swapfile.size = "64G";
                      };
                    };
                  };

                  mountpoint = "/partition-root";
                };
              };
            };
          };
        };
      };
    };
  };
}
