{ config, pkgs, inputs, ... }:
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

  unstable = import inputs.unstable;
  master = import inputs.master;
in
{
  disabledModules = [ "services/misc/ollama.nix" "services/misc/open-webui.nix" ];

  imports = [
    ./..
    ./hardware-configuration.nix
    ../kernel.nix
    # ../pipewire.nix
    ../virtualization.nix
    ../desktop.nix
    ../userscompat.nix

    (inputs.master + /nixos/modules/services/misc/open-webui.nix)
    (inputs.master + /nixos/modules/services/misc/ollama.nix)
  ];

  services.open-webui = {
    enable = true;
    host = "10.10.10.221";
    port = 8080;
    environment = {
      SCARF_NO_ANALYTICS = "True";
      DO_NOT_TRACK = "True";
      ANONYMIZED_TELEMETRY = "False";
      OLLAMA_API_BASE_URL = "http://ollama.home.arpa:11434";
      WEBUI_AUTH = "False";
      GLOBAL_LOG_LEVEL = "DEBUG";
      NLTK_DATA = "/nix/store/96kmjbzhpyisickrhgmkkaawnvrn9sj3-nltk-data";
    };
    package = pkgs.master.open-webui;
  };
  services.ollama = {
    enable = true;
    #    host = "10.10.10.220";
    host = "0.0.0.0";
    acceleration = "cuda";
    package = inputs.ollama.packages.x86_64-linux.cuda;
    #      package = pkgs.ollama.packages.cuda;
    environmentVariables = {
      # TODO what is the var to control how long ollama takes to purge a model? Future mitch fix it.
      OLLAMA_MAX_LOADED_MODELS = "1";
      OLLAMA_NUM_PARALLEL = "1";
    };
  };

  services.udev.extraRules = ''
    # These are the udev rules for accessing the USB interfaces of the UHK as non-root users.
    # Copy this file to /etc/udev/rules.d and physically reconnect the UHK afterwards.
    SUBSYSTEM=="input", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="612[0-7]", GROUP="input", MODE="0660"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="612[0-7]", TAG+="uaccess", MODE="0660", GROUP="input"
    KERNEL=="hidraw*", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="612[0-7]", TAG+="uaccess", MODE="0660", GROUP="input"

    # Streameck rules
    SUBSYSTEM=="usb", ATTR{idVendor}=="0fd9", ATTR{idProduct}=="0060", MODE="0660", GROUP="input"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0fd9", ATTR{idProduct}=="0063", MODE="0660", GROUP="input"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0fd9", ATTR{idProduct}=="006c", MODE="0660", GROUP="input"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0fd9", ATTR{idProduct}=="006d", MODE="0660", GROUP="input"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0fd9", ATTR{idProduct}=="008f", MODE="0660", GROUP="input"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0fd9", ATTR{idProduct}=="0090", MODE="0660", GROUP="input"
  '';

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


  nixpkgs.config.allowUnfree = true;

  environment = {
    systemPackages = [
      pkgs.uhk-agent
      pkgs.uhk-udev-rules

      pkgs.unstable.cudatoolkit
      pkgs.unstable.autoAddDriverRunpath
      pkgs.unstable.autoFixElfFiles
    ];
    etc = {
      "NetworkManager/dnsmasq.d/libvirt-dnsmasq.conf".text = ''
        server=/dev.home.arpa/10.200.200.1
      '';
    };
  };

  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_6;

  hardware = {
    opengl.enable = true;
    nvidia = {
      modesetting.enable = true;
      powerManagement = {
        # until I get prime/offload working, can't abuse this
        enable = false;
        finegrained = false;
      };
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };

  # hardware = {
  #   #TODO get this hybrid gpu setup to work
  #   opengl.enable = true;
  #   nvidia = {
  #     modesetting.enable = true;
  #     nvidiaPersistenced = true;
  #     #      nvidiaSettings = true;
  #     open = false;
  #     package = config.boot.kernelPackages.nvidiaPackages.stable;
  #     # powerManagement = {
  #     #   enable = true;
  #     #   finegrained = true;
  #     # };
  #     prime = {
  #       #        allowExternalGpu = true;
  #       amdgpuBusId = "PCI:6b:0:0";
  #       nvidiaBusId = "PCI:1:0:0";
  #       offload = {
  #         enable = true;
  #         enableOffloadCmd = true;
  #       };
  #     };
  #   };
  # };

  boot.blacklistedKernelModules = [ "nouveau" "nvidia" "nvidia_drm" "nvidia_modeset" ];

  networking = {
    hosts = {
      "10.200.200.253" = [
        "demo.dev.home.arpa"
        "ai.dev.home.arpa"
      ];
    };
    hostName = "rtx";
    hostId = "126688e2";
    firewall = {
      trustedInterfaces = [
        "wlp8s0"
        "eno1"
        "wlo1"
      ];
    };
    wireless.enable = false;
    networkmanager = {
      logLevel = "DEBUG";
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

  services = {
    openssh = {
      extraConfig = ''
        UseDNS no
      '';
      enable = true;
      permitRootLogin = "yes";
    };
    xserver = {
      displayManager.gdm.autoSuspend = false;
      #videoDrivers = [ "nvidia" "amdgpu" ]; # no worky y?
      videoDrivers = [ "nvidia" ];
    };
  };

  # For some reason things are suspending all the time

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.login1.suspend" ||
            action.id == "org.freedesktop.login1.suspend-multiple-sessions" ||
            action.id == "org.freedesktop.login1.hibernate" ||
            action.id == "org.freedesktop.login1.hibernate-multiple-sessions")
        {
            return polkit.Result.NO;
        }
    });
  '';


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
      tmpfsSize = "40%";
    };

    #    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
    initrd = {
      kernelModules = [
        "zfs"
        "vfat"
        "amdgpu"
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
    extraModulePackages = with config.boot.kernelPackages; [
      acpi_call
      chipsec
      zfs
      #      inputs.unstable.legacyPackages.x86_64-linux.linuxPackages.nvidia_x11
      #      pkgs.unstable.linuxPackages.nvidia_x11
    ];
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

  networking.interfaces.eno1 = {
    useDHCP = true;
    ipv4.addresses = [
      {
        address = "10.10.10.220";
        prefixLength = 32;
      }
      {
        address = "10.10.10.221";
        prefixLength = 32;
      }
    ];
  };
}
