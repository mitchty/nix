{ config, pkgs, lib, ... }:

{
  imports =
    [
      # Ordering of imports is for understanding not alphanumeric sorted
      ./hardware-configuration.nix
      ../nix.nix
      ../network.nix
      ../pipewire.nix
      ../graphics.nix
      ../virtualization.nix
      ../console.nix
      ../users.nix
      ./zfs.nix
    ];


  networking.hostId = "30d18215";
  networking.firewall.enable = false;

  users.users.root.initialPassword = "changeme";

  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
  };

  # Non dhcp hostname
  networking.hostName = "nexus";

  # zsh for a login shell, bash is silly
  programs.zsh.enable = true;

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
    google-chrome
    intel-media-driver
    kmix
    libv4l
    libvirt
    linuxPackages.perf
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
    yakuake
    # TODO: These need to go into home-manager somehow...
    # We want newer/more recent nixpkg versions of obs etc...
    # obs-studio
    # obs-v4l2sink
    #unstable.obs-studio
    #unstable.obs-v4l2sink
    # vlc
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;

  # This config is for nixos release 21.11
  system.stateVersion = "21.11";

  # And allow passwordless sudo for wheel
  security.sudo.extraConfig = ''
    %wheel ALL=(root) NOPASSWD:ALL
  '';
}
