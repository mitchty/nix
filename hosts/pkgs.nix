{ pkgs, lib, ... }: {
  # Only allow certain unfree packages to install
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "google-chrome"
  ];

  nixpkgs.config.packageOverrides = pkgs: {
    qemu = pkgs.qemu.override { gtkSupport = true; };
  };

  # Default system packages, note, should be minimal, for now using it to be
  # lazy until I get home-manager setup. Also not sure which of these I want to
  # be in home-manager and not...
  environment.systemPackages = with pkgs; [
    element-desktop
    google-chrome
    intel-media-driver
    kmix
    libv4l
    libvirt
    linuxPackages.cpupower
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
    s-tui
    sddm
    strace
    tmux
    xorg.xauth
    yakuake
  ];
}
