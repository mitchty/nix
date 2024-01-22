{ config, pkgs, ... }: {
  imports =
    [
      ./..

      # Ordering of imports is for understanding not alphanumeric sorted
      ./hardware-configuration.nix
      ../kernel.nix
      # ../pipewire.nix
      ../virtualization.nix
      ../desktop.nix
      ../userscompat.nix
      ../laptop.nix
    ];

  config = {
    system.stateVersion = "23.11";
    networking = {
      wireless.enable = false;
      networkmanager.enable = true;
    };
    networking.firewall = {
      enable = true;
      trustedInterfaces = [ "eno1" ];

      interfaces = {
        "wlp2s0" = {
          allowedTCPPorts = [ 22 9002 ];
          allowedUDPPorts = [ ];
        };
      };
    };
    boot = {
      kernelParams = [
        "boot.shell_on_fail"
        "iomem=relaxed"
        "intel-spi.writeable=1"
      ];
      supportedFilesystems = [
        "zfs"
        "xfs"
        "ext4"
      ];
      loader = {
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/efiboot/efi0";
        };
        systemd-boot = {
          enable = true;
          configurationLimit = 10;
          memtest86.enable = true;
        };
        generationsDir.copyKernels = true;
      };
      extraModulePackages = with config.boot.kernelPackages; [ acpi_call chipsec zfs ];
    };

    # Generated stuff goes under here...
    networking.hostName = "wm2";
    networking.hostId = "32643aa7";
    boot.loader.systemd-boot.extraInstallCommands = ''
      mount -t vfat -o iocharset=iso8859-1 /dev/disk/by-partlabel/ESP0 /efiboot/efi0
      mount -t vfat -o iocharset=iso8859-1 /dev/disk/by-partlabel/ESP1 /efiboot/efi1
      cp -r /efiboot/efi0/* /efiboot/efi1
    '';
    boot.swraid.enable = true;
    boot.swraid.mdadmConf = ''
      ARRAY /dev/md/SWAPMD level=raid1 num-devices=2 metadata=1.0 name=autoinstall:SWAPMD UUID=1f7f9662:a3c9d763:0474afbf:b827718d
         devices=/dev/nvme0n1p2,/dev/nvme1n1p2
      PROGRAM ${pkgs.coreutils}/bin/true
    '';
    boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
    boot.initrd.kernelModules = [ "zfs" ];
    boot.initrd.postDeviceCommands = "zpool import -lf zpool";
    boot.zfs.devNodes = "/dev/disk/by-partlabel";
    # networking.interfaces.enp103s0f4u1c2.useDHCP = true;
    #    networking.interfaces.wlp2s0.useDHCP = true;
    services.openssh.extraConfig = ''
      UseDNS no
    '';
  };
}
