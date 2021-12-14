{ config, pkgs, lib, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.supportedFilesystems = [ "zfs" ];
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.devNodes = "/dev/disk/by-partuuid";

  networking.hostId = "30d18215";
  networking.firewall.enable = false;

  users.users.root.initialPassword = "changeme";

  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
  };

  # Non dhcp hostname
  networking.hostName = "nexus";

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Enable the Plasma 5 Desktop Environment.
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # TODO: review this setup, would like to have login for local but not xrdp
  #  services.xserver.displayManager.autoLogin = {
  #    enable = true;
  #    user = "mitch";
  #  };

  # Related to plasma/x we want pulse
  nixpkgs.config = {
    pulse = true;
    packageOverrides = pkgs: {
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
  };

  # Until nix 2.4 is shipped in a version of nixos, bit of hacks to get things
  # to work.
  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Configure keymap in X11
  services.xserver.layout = "us";

  # zsh for a login shell, bash is silly
  programs.zsh.enable = true;

  # TODO: can home-manager sort this out now?
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
  ];

  # Default system packages, note, should be minimal, for now using it to be
  # lazy until I get home-manager setup. Also not sure which of these I want to
  # be in home-manager and not...
  environment.systemPackages = with pkgs; [
    element-desktop
    firefox
    google-chrome
    intel-media-driver
    kmix
    libv4l
    libvirt
    linuxPackages.perf
    mosh
    networkmanager
    networkmanager-openconnect
    networkmanagerapplet
    openconnect
    openresolv
    openvpn
    pavucontrol
    pipewire
    plasma-desktop
    plasma-integration
    plasma-pa
    rtkit
    sddm
    xorg.xauth
    xrdp
    yakuake
    # TODO: These need to go into home-manager somehow...
    # We want newer/more recent nixpkg versions of obs etc...
    # obs-studio
    # obs-v4l2sink
    #unstable.obs-studio
    #unstable.obs-v4l2sink
    # vlc
  ];

  # For the qemu-agent integration for kvm/qemu
  services.qemuGuest.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;

  # Use xrdp for gui usage for this node
  # TODO: once pikvm is working maybe see if that is worth using instead
  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager = "startplasma-x11";
  networking.firewall.allowedTCPPorts = [ 3389 3350 5900 ];
  networking.firewall.allowedUDPPortRanges = [{ from = 60000; to = 60010; }];
  networking.networkmanager.enable = true;
  networking.enableIPv6 = false;

  # This config is for nixos release 21.11
  system.stateVersion = "21.11";

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

  # Use the latest packaged kernel rev with zfs support
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

  # TODO: lets try pipewire, this needs review with OBS...
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
          args = { };
        }
        { name = "libpipewire-module-adapter"; }
        { name = "libpipewire-module-link-factory"; }
        { name = "libpipewire-module-session-manager"; }
      ];
    };
  };

  # TODO: Lets re-enable ipv6 soon
  boot.kernelParams = [ "ipv6.disable=1" ];

  # Default queueing discipline will be controlled delay
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
