{ config, pkgs, ... }:
let
  fsAutomountOpts = [
    "x-systemd.automount"
    "nofail"
    "x-systemd.idle-timeout=300"
    "x-systemd.mount-timeout=60s"
  ];
  fsCifsPerfOpts = [
    "bsize=8388608"
    "rsize=130048"
    #"cache=loose" # TODO need to test this between nodes
  ];
  fsCifsDefaults = [
    "nofail"
    "user"
    "forceuid"
    "forcegid"
    "soft"
    "rw"
    "vers=3"
    "credentials=${config.age.secrets."cifs/mitch".path}"
  ];
  fsUserMedia = [
    "uid=3000"
    "gid=3000"
  ];
  fsUserMe = [
    "uid=1000"
    "gid=100"
  ];
in
{
  imports = [
      ./..

      ./hardware-configuration.nix
      ../kernel.nix
      # ../pipewire.nix
      ../virtualization.nix
      ../desktop.nix
      ../userscompat.nix
  ];

   fileSystems = {
      "/nas/internets" = {
        device = "//s1.home.arpa/internets";
        fsType = "cifs";
        options = fsCifsDefaults ++ fsAutomountOpts ++ fsCifsPerfOpts ++ fsUserMe;
      };
      "/nas/media" = {
        device = "//s1.home.arpa/media";
        fsType = "cifs";
        options = fsCifsDefaults ++ fsAutomountOpts ++ fsCifsPerfOpts ++ fsUserMe;
      };
      "/nas/bitbucket" = {
        device = "//s1.home.arpa/bitbucket";
        fsType = "cifs";
        options = fsCifsDefaults ++ fsAutomountOpts ++ fsCifsPerfOpts ++ fsUserMe;
      };
      "/nas/backup" = {
        device = "//s1.home.arpa/backup";
        fsType = "cifs";
        options = fsCifsDefaults ++ fsAutomountOpts ++ fsCifsPerfOpts ++ fsUserMe;
      };
    };

    environment.etc = {
      "NetworkManager/dnsmasq.d/libvirt-dnsmasq.conf".text = ''
        server=/dev.home.arpa/10.200.200.1
      '';
    };
    networking = {
      hostName = "rtx";
      hostId = "126688e2";
      firewall = {
        trustedInterfaces = [
          "enp6s0"
          "wlo1"
        ];
      };
      wireless.enable = false;
      networkmanager = {
        enable = true;
        wifi.powersave = false;
        dns = "dnsmasq";
      };
      # firewall = {
      #   interfaces = {
      #     wlanIface = {
      #       allowedTCPPorts = [ 22 9002 ]; # TODO: need to get wireguard working so I can allow all the monitoring stuff off that shit
      #       allowedUDPPorts = [ ];
      #     };
      #     ethIface = {
      #       allowedTCPPorts = [ 22 9002 ];
      #       allowedUDPPorts = [ ];
      #     };
      #   };
      # };
    };

    services.openssh = {
      extraConfig = ''
      UseDNS no
    '';
    enable = true;
    permitRootLogin = "yes";
                       };

    boot = {
      # Boosts overall write speed for cifs
      extraModprobeConfig = ''
        options cifs CIFSMaxBufSize=130048
      '';

      tmp = {
        cleanOnBoot = true;
        useTmpfs = true;
        # Compiling the linux kernel takes at least 20GiB, so set it
        # to 32GiB for when I'm mobile and compiling sized higher
        # cause the effing rocm driver compilation takes like 34GiB,
        # sigh... I need a laptop with 128GiB of rams apparently.
        #
        # Stupid ollama derivations and amd driver shenanigans BOO
        # URNS I say.
        tmpfsSize = "60%";
      };

      kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
      initrd = {
        kernelModules = [
          "zfs"
          "vfat"
          #          "amdgpu"
        ];
        postDeviceCommands = "zpool import -lf zpool";
      };

      kernelParams = [
        "boot.shell_on_fail"
        "iomem=relaxed"
        "intel-spi.writeable=1"
        "usbcore.autosuspend=-1"
      ];
      supportedFilesystems = [
        "zfs"
        "xfs"
        "ext4"
        "vfat"
      ];
      loader = {
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/efiboot/efi0";
        };

        # TODO: make a systemd-boot mirroring module for nixos
        systemd-boot = {
          enable = true;
          configurationLimit = 20;
          memtest86.enable = true;
          #
          # TODO: I think I set up this laptop wrong, efi0 is what efi1 shoulda
          # been oops, put the disks in the wrong order apparently as to which
          # one gets enumerated first by the nvme driver. ffs I hate technology
          # some days.
          #
          # When I get the autobuild crap working I'll fix it then and probably
          # change this to /boot/efiN instead of this /efiboot rubbish I pulled
          # out of my ass apparently.
          extraInstallCommands = ''
            set -e
            if ! ${pkgs.util-linux}/bin/mountpoint -q /efiboot/efi0; then
              ${pkgs.util-linux}/bin/mount -t vfat -o iocharset=iso8859-1 /dev/disk/by-partlabel/ESP0 /efiboot/efi0
            fi
            if ! ${pkgs.util-linux}/bin/mountpoint -q /efiboot/efi1; then
              ${pkgs.util-linux}/bin/mount -t vfat -o iocharset=iso8859-1 /dev/disk/by-partlabel/ESP1 /efiboot/efi1
            fi
            ${pkgs.rsync}/bin/rsync -Havz --checksum --exclude .lost+found --delete --delete-before /efiboot/efi0/ /efiboot/efi1
          '';
        };
        generationsDir.copyKernels = true;
      };

      swraid = {
        enable = true;
mdadmConf = ''
    PROGRAM ${pkgs.coreutils}/bin/true
    ARRAY /dev/md/chonkyboi:SWAPMD level=raid1 num-devices=2 metadata=1.0
       devices=/dev/disk/by-partlabel/SWAP0,/dev/disk/by-partlabel/SWAP1
  '';
      };
      extraModulePackages = with config.boot.kernelPackages; [ acpi_call chipsec zfs ];
      zfs.devNodes = "/dev/disk/by-partlabel";
    };

    # Generated stuff goes under here...

  environment = {
    variables = {
      # Since we have no swap, have the heap be a bit less extreme
      GC_INITIAL_HEAP_SIZE = "1M";
    };
  };

  # services = {
  #   ollama = {
  #     enable = true;
  #   };
  #   open-webui = {
  #     enable = true;
  #   };
  # };
  users.mutableUsers = false;

  system.stateVersion = "24.05";

  networking.interfaces.enp6s0.useDHCP = true;
}
