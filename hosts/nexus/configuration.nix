{ config, pkgs, lib, ... }:

{
  imports =
    [
      # Ordering of imports is for understanding not alphanumeric sorted
      ./hardware-configuration.nix
      ./nix.nix
      ./network.nix
      ./pipewire.nix
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
    package = pkgs.nix_2_4;
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

  # This config is for nixos release 21.11
  system.stateVersion = "21.11";


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
