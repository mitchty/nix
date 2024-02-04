{ lib, pkgs, options, ... }:

with lib;

let
  name = "gui";
in
{
  options.roles.${name} = {
    enable = mkEnableOption "For now used to indicate a system is/n't one that has a graphical login.";
  };

  # darwin is ignored for now, mostly just a boolean oracle for home-manager there
  #  config = mkIf config.roles.${name}.enable
  config = {
    # google-chrome is unfree so make sure nixpkgs lets us use it
    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [
      element-desktop
      google-chrome
      intel-media-driver
      kmix
      libv4l
      libvirt
      networkmanager
      networkmanager-openconnect
      networkmanagerapplet
      pavucontrol
      pipewire
      plasma-desktop
      plasma-integration
      plasma-pa
      rtkit
      sddm
      xorg.xauth
      yakuake
    ];

    # Capslock is control, I'm not a heathen.
    services.xserver.xkbOptions = "ctrl:swapcaps";

    # Configure keymap in X11
    services.xserver.layout = "us";

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

    # Enable the Plasma 5 Desktop Environment.
    services.xserver.enable = true;
    services.xserver.displayManager.sddm.enable = true;
    services.xserver.desktopManager.plasma5.enable = true;
  };
}
