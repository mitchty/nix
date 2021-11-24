{ config, pkgs, lib, ... }:
let
  # unstableTarball =
  #   fetchTarball
  #     https://github.com/NixOS/nixpkgs/archive/nixpkgs-unstable.tar.gz;
  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.supportedFilesystems = [ "zfs" ];
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.devNodes = "/dev/disk/by-partuuid";

  networking.interfaces.eno1.ipv4.addresses = [ {
    address = "10.10.10.10";
    prefixLength = 24;
  } ];

  networking.defaultGateway = "10.10.10.1";
  networking.nameservers = [ "10.10.10.1" ];
  networking.hostId = "30d18215";
  networking.firewall.enable = false;

  # boot.kernelParams = [ "boot.shell_on_fail" ];

  users.users.root.initialPassword = "changeme";

  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
  };

  # Non dhcp hostname
  networking.hostName = "nexus";

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  # Enable the Plasma 5 Desktop Environment.
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
#  services.xserver.displayManager.autoLogin = {
#    enable = true;
#    user = "mitch";
#  };

  # Related to plasma/x we want pulse
  nixpkgs.config = {
    pulse = true;
    # packageOverrides = pkgs: {
    #   unstable = import unstableTarball {
    #     config = config.nixpkgs.config;
    #   };
    # };
  };

  # Configure keymap in X11
  services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
#  services.xserver.libinput.enable = true;

  # zsh for a login shell, bash is silly
  programs.zsh.enable = true;

  # My normal user account
  users.users.mitch = {
    isNormalUser = true;
    description = "Mitchell James Tishmack";
    home = "/home/mitch";
    createHome = true;
    shell = pkgs.zsh;
    initialPassword = "changeme";
    extraGroups = [
      "audio"
      "docker"
      "jackaudio"
      "libvirtd"
      "networkmanager"
      "video"
      "wheel"
    ];
  };

  # TODO: figure this out
  # Only what is defined, no manual crap
  users.mutableUsers = false;

  # Lets let arm stuff run easily
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Only allow certain unfree packages to install
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "google-chrome"
    "slack"
    "teams"
  ];

  # Default system packages, note, should be minimal, for now using it to be
  # lazy until I get home-manager setup
  environment.systemPackages = with pkgs; [
    libv4l
    rtkit
    kmix
    plasma-pa
    intel-media-driver
    ag
    alacritty
    bind
    curl
    docker
    docker-compose
    emacs
    element-desktop
    firefox
    git
    git-lfs
    gitAndTools.transcrypt
    google-chrome
    htop
    libvirt
    mosh
    networkmanager
    networkmanager-openconnect
    networkmanagerapplet
    niv
    openvpn
    openresolv
    # We want newer/more recent nixpkg versions of obs etc...
    obs-studio
    obs-v4l2sink
    #unstable.obs-studio
    #unstable.obs-v4l2sink
    pavucontrol
    # pulseaudio
    plasma-desktop
    plasma-integration
    sddm
    slack
    syncthing
    teams
    openconnect
    tmux
    pipewire
    tcpdump
    #vagrant
    yakuake
    xpra
    xrdp
    xorg.xauth
    vim
    vlc
    wget
    zsh
  ];

  # For the qemu-agent integration for kvm/qemu
  services.qemuGuest.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # This no work with xquartz, why? who knows figure it out later future me if ever.
#  services.openssh.forwardX11 = true;
#  programs.ssh.forwardX11 = true;
#  programs.ssh.setXAuthLocation = true;

  services.xrdp.enable = true;
  #services.xrdp.defaultWindowManager = "startplasma-x11";
  services.xrdp.defaultWindowManager = "startplasma-x11";
  networking.firewall.allowedTCPPorts = [ 3389 3350 5900 ];
  networking.firewall.allowedUDPPortRanges = [ {from = 60000; to = 60010; }];

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
  networking.networkmanager.enable = true;
  networking.enableIPv6 = false;

  # Non networkmanager setup, deal with this later
#  networking.wireless.enable = true;
#  networking.wireless.networks = {
#    newhotness = {
#      psk = "changeme";
#    };
#  };
#  networking.networkmanager.unmanaged = [
#    "*" "except:type:wwan" "except:type:gsm"
#  ];

  # This config is for nixos release 21.05
  system.stateVersion = "21.05";

  # Clean /tmp at boot time
  boot.cleanTmpDir = true;

  # Enable ntp
  services.timesyncd.enable = true;

  # Save space not enabling docs
  documentation.nixos.enable = false;

  # gc old generations
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 60d";

  # And allow passwordless sudo for wheel
  security.sudo.extraConfig = ''
    %wheel ALL=(root) NOPASSWD:ALL
  '';

  # Capslock is control, I'm not a heathen.
  services.xserver.xkbOptions = "ctrl:swapcaps";

  # Configure dri/vaapi support for ffmpeg so OBS can use the intel hardware encoding
  hardware.opengl = {
    driSupport = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      vaapiIntel
      intel-media-driver
    ];
  };
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

  # Use/setup libvirtd/docker
  virtualisation.libvirtd.enable = true;
  virtualisation.docker.enable = true;

  # Use the latest packaged kernel rev (can't zfs broken on latest...)
  #boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelPackages = pkgs.linuxPackages;
  nixpkgs.config.packageOverrides = pkgs: {
    linux = pkgs.linux.override {
        extraConfig = ''
          USB_CONFIGFS y
          USB_CONFIGFS_F_UVC y
          USB_CONFIGFS_F_UAC1 y
          USB_CONFIGFS_F_UAC2 y
          USB_GADGET y
          USB_GADGETFS y
        '';
    };
  };

  # lets try pipewire
  security.rtkit.enable = true;
  hardware.pulseaudio.enable = false;
  programs.dconf.enable = true;

  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    # alsa.enable = true;
    # alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    socketActivation = true;
    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    # media-session.enable = true;

    config.pipewire-pulse = {
      "context.properties" = {
        "log.level" = 2;
      };
      "context.modules" = [
        {
          name = "libpipewire-module-rtkit";
          args = {
            "nice.level" = -15;
            "rt.prio" = 88;
            "rt.time.soft" = 200000;
            "rt.time.hard" = 200000;
          };
          flags = [ "ifexists" "nofail" ];
        }
        { name = "libpipewire-module-protocol-native"; }
        { name = "libpipewire-module-client-node"; }
        { name = "libpipewire-module-adapter"; }
        { name = "libpipewire-module-metadata"; }
        {
          name = "libpipewire-module-protocol-pulse";
          args = {
            "pulse.min.req" = "256/48000";
            "pulse.default.req" = "256/48000";
            "pulse.max.req" = "256/48000";
            "pulse.min.quantum" = "256/48000";
            "pulse.max.quantum" = "1024/48000";
            "server.address" = [ "unix:native" ];
          };
        }
      ];
      "stream.properties" = {
        "node.latency" = "256/48000";
        "resample.quality" = 1;
      };
    };

    config.pipewire = {
      "context.properties" = {
        "link.max-buffers" = 32;
        "log.level" = 2;
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 256;
        "default.clock.min-quantum" = 256;
        "default.clock.max-quantum" = 1024;
        "core.daemon" = true;
        "core.name" = "pipewire-0";
        "mem.allow-mlock" = true;
      };
      "context.modules" = [
        {
          name = "libpipewire-module-rtkit";
          args = {
            "nice.level" = -15;
            "rt.prio" = 88;
            "rt.time.soft" = 200000;
            "rt.time.hard" = 200000;
          };
          flags = [ "ifexists" "nofail" ];
        }
        { name = "libpipewire-module-protocol-native"; }
        { name = "libpipewire-module-profiler"; }
        { name = "libpipewire-module-metadata"; }
        { name = "libpipewire-module-spa-device-factory"; }
        { name = "libpipewire-module-spa-node-factory"; }
        { name = "libpipewire-module-client-node"; }
        { name = "libpipewire-module-client-device"; }
        {
          name = "libpipewire-module-portal";
          flags = [ "ifexists" "nofail" ];
        }
        {
          name = "libpipewire-module-access";
          args = {};
        }
        { name = "libpipewire-module-adapter"; }
        { name = "libpipewire-module-link-factory"; }
        { name = "libpipewire-module-session-manager"; }
      ];
    };
  };


  # blah
  boot.kernelParams = [ "ipv6.disable=1" ];

  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq_codel";
  };

  # Loopback device/kernel module config for obs
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
  boot.kernelModules = with config.boot.kernelModules; [
    "v4l2loopback"
    "kvm_intel"
  ];

  # Top is the video loopback device options
  # kvm_intel nested is set so we can nest vm's in kvm vm's
  boot.extraModprobeConfig = ''
    options kvm_intel nested=1
    options v4l2loopback exclusive_caps=1 video_nr=9 card_label="obs"
    '';
}
