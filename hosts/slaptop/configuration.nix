{ config, pkgs, lib, ... }: {
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.enableCryptodisk = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.gfxmodeEfi = "1024x768";

  boot.initrd.luks.devices = {
    crypted = {
      device = "/dev/disk/by-uuid/fdd79b6e-151d-476e-aa88-c6f1f2de3fe5";
      preLVM = true;
    };
  };

  # Non dhcp hostname
  networking.hostName = "slaptop";

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.wlp82s0.useDHCP = true;

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
  services.xserver.displayManager.autoLogin = {
    enable = true;
    user = "mitch";
  };

  # Related to plasma/x we want pulse
  nixpkgs.config.pulse = true;

  # Configure keymap in X11
  services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # zsh for a login shell, bash is silly
  programs.zsh.enable = true;

  # My normal user account
  users.users.mitch = {
    isNormalUser = true;
    description = "Mitchell James Tishmack";
    home = "/home/mitch";
    createHome = true;
    shell = pkgs.zsh;
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
  #  users.mutableUsers = false;

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

  nixpkgs.config.packageOverrides = pkgs: {
    qemu = pkgs.qemu.override { gtkSupport = true; };
  };

  # For flatpak apps like rocket.chat
  services.flatpak.enable = true;

  # For the qemu-agent integration for kvm/qemu
  services.qemuGuest.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
  };

  # This no work with xquartz, why? who knows figure it out later future me if ever.
  #  services.openssh.forwardX11 = true;
  #  programs.ssh.forwardX11 = true;
  #  programs.ssh.setXAuthLocation = true;

  # Try out xrdp instead for macos->nixos remoting
  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager = "startplasma-x11";
  networking.firewall.allowedTCPPorts = [ 3389 3350 5900 22000 ];
  networking.firewall.allowedUDPPortRanges = [{ from = 21027; to = 21027; } { from = 22000; to = 22000; } { from = 60000; to = 60010; }];

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
  networking.networkmanager.enable = true;
  networking.enableIPv6 = false;

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

  # Laptop power management, reduce noisy af fan noise of this laptop
  # Ref: https://linrunner.de/tlp/settings/introduction.html
  services.tlp = {
    enable = true;
    settings = {
      CPU_MAX_PERF_ON_AC = 95;
      CPU_MAX_PERF_ON_BAT = 60;
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      ENERGY_PERF_POLICY_ON_AC = "powersave";
      ENERGY_PERF_POLICY_ON_BAT = "powersave";
      SCHED_POWERSAVE_ON_AC = "1";
      SCHED_POWERSAVE_ON_BAT = "1";
      TLP_DEFAULT_MODE = "BAT";
      TLP_PERSISTENT_DEFAULT = "1";
      START_CHARGE_THRESH_BAT0 = 50;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };

  # TODO: someday use this when the bat charge stuff works on more than lenovo
  # laptops, LAAAAAMEE
  # # Run tlp fullcharge to fully charge when wanted

  # Use/setup libvirtd/docker
  virtualisation.libvirtd.enable = true;
  virtualisation.docker.enable = true;

  # Use the latest packaged kernel rev
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Audio shenanigans, use the full pulse audio install, it seems to work.
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.package = pkgs.pulseaudioFull.override { jackaudioSupport = true; };

  services.jack = {
    jackd.enable = true;
    alsa.enable = false;
    loopback = {
      enable = true;
    };
  };

  # Also make sure that we have a virtualspeaker+monitor so audio can be routed
  # from obs to other apps
  hardware.pulseaudio.extraConfig = ''
    load-module module-null-sink sink_name=Virtual-Speaker sink_properties=device.description=Virtual-Speaker
    load-module module-remap-source source_name=Remap-Source master=Virtual-Speaker.monitor
  '';

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

  services.resolved = {
    enable = true;
    fallbackDns = [ "8.8.8.8" "2001:4860:4860::8844" ];
  };
  services.openvpn.servers = {
    fremont = {
      config = '' config /home/mitch/src/github.com/rancherlabs/fremont/VPN/Ranch01/ranch01-fremont-udp.ovpn '';
      up = "${pkgs.openvpn}/libexec/update-systemd-resolved";
      down = "${pkgs.openvpn}/libexec/update-systemd-resolved";
    };
  };
}
