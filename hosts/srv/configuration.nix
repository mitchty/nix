{ config, pkgs, inputs, ... }:
let
  unstable = import inputs.latest;
in
{
  disabledModules = [ "services/misc/ollama.nix" "services/misc/open-webui.nix" ];
  imports = [
    ./..
    ./hardware-configuration.nix
    ../kernel.nix
    ../virtualization.nix
    ../desktop.nix
    ../zfs-grub.nix
    ../userscompat.nix

    # Import the open-webui and ollama module from unstable
    (inputs.unstable + /nixos/modules/services/misc/open-webui.nix)
    (inputs.unstable + /nixos/modules/services/misc/ollama.nix)
  ];

  config = {
    system.stateVersion = "22.05";

    # services.open-webui = {
    #   enable = true;
    #   host = "10.10.10.221";
    #   port = 8888;
    # };
    # services.ollama = {
    #   enable = true;
    #   host = "10.10.10.220";
    #   acceleration = "cuda";
    #   package = inputs.ollama.packages.x86_64-linux.cuda;
    #   #      package = pkgs.ollama.packages.cuda;
    # };

    services.zfs.autoScrub.enable = true;
    environment = {
      systemPackages = [
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

    hardware = {
      opengl.enable = true;

      nvidia = {
        modesetting.enable = true;
        powerManagement.enable = true;
        powerManagement.finegrained = false;
        open = true;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };
    };

    services = {
      xserver.videoDrivers = [ "nvidia" ];
    };

    boot = {
      blacklistedKernelModules = [ "nouveau" "nvidia" "nvidia_drm" "nvidia_modeset" ];
      extraModulePackages = [
        pkgs.linuxPackages.nvidia_x11
      ];
    };

    networking = {
      hostName = "srv";
      hostId = "81297957";

      networkmanager = {
        enable = true;
        wifi.powersave = false;
        dns = "dnsmasq";
      };
      firewall = {
        enable = true;
        checkReversePath = false;
        logReversePathDrops = true;
        logRefusedPackets = true;
        logRefusedConnections = true;
        trustedInterfaces = [ "eno1" "enp142s0" "virbr1" ];
        allowedTCPPorts = [
          8888
          11434
        ];
        #interfaces.enp142s0.
        # interfaces = {
        #   "eno1" = {
        #     allowedTCPPorts = [ 22 9002 ];
        #     allowedUDPPorts = [ ];
        #   };
        # };
      };
      #      bridges.br0.interfaces = [ "eno1" ];

      interfaces = {
        eno1.useDHCP = true;
        eno2.useDHCP = true;
        eno3.useDHCP = true;
        eno4.useDHCP = true;
        enp142s0 = {
          useDHCP = true;
        };
      };
    };
    boot = {
      # Boosts overall write speed for cifs
      extraModprobeConfig = ''
        options cifs CIFSMaxBufSize=130048
      '';

      loader = {
        generationsDir.copyKernels = true;
        grub = {
          configurationLimit = 9;
          mirroredBoots = [
            { devices = [ "nodev" ]; path = "/boot"; }
            { devices = [ "nodev" ]; path = "/boot1"; }
            { devices = [ "nodev" ]; path = "/boot2"; }
          ];
        };
      };
    };
  };
}
