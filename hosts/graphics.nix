{ pkgs, ... }: {
  # Use xrdp for gui usage for this node
  # TODO: once pikvm is working maybe see if that is worth using instead
  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager = "startplasma-x11";

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

  # TODO: review this setup, would like to have login for local but not xrdp
  #  services.xserver.displayManager.autoLogin = {
  #    enable = true;
  #    user = "mitch";
  #  };
}
