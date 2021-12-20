{ config, pkgs, lib, ... }: {
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../nix.nix
      ../network.nix
      ../pipewire.nix
      ../graphics.nix
      ../virtualization.nix
      ../console.nix
      ../users.nix
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

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.wlp82s0.useDHCP = true;

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

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # zsh for a login shell, bash is silly
  programs.zsh.enable = true;

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

  # nixpkgs.config.packageOverrides = pkgs: {
  #   qemu = pkgs.qemu.override { gtkSupport = true; };
  # };

  # For flatpak apps like rocket.chat
  services.flatpak.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
  };

  # Try out xrdp instead for macos->nixos remoting
  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager = "startplasma-x11";

  system.stateVersion = "21.11";

  # And allow passwordless sudo for wheel
  security.sudo.extraConfig = ''
    %wheel ALL=(root) NOPASSWD:ALL
  '';

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
  # Run tlp fullcharge to fully charge when wanted

  # Use the latest packaged kernel rev
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # TODO: Keep?
  # Also make sure that we have a virtualspeaker+monitor so audio can be routed
  # from obs to other apps
  # hardware.pulseaudio.extraConfig = ''
  #   load-module module-null-sink sink_name=Virtual-Speaker sink_properties=device.description=Virtual-Speaker
  #   load-module module-remap-source source_name=Remap-Source master=Virtual-Speaker.monitor
  # '';

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
