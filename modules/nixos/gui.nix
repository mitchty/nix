{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.role.gui;
in
{
  options.services.role.gui = {
    enable = mkEnableOption "For now used to indicate a system is/n't one that has a graphical login.";
  };

  # TODO: need to do more modularization with this stuff, for now its copypasta.
  config = mkIf cfg.enable {
    # Only allow certain unfree packages to install
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "google-chrome"
    ];

    # gooey stuff for qemu
    nixpkgs.config.packageOverrides = pkgs: {
      qemu = pkgs.qemu.override { gtkSupport = true; };
    };

    environment.systemPackages = [
      pkgs.element-desktop
      pkgs.google-chrome
      pkgs.intel-media-driver
      pkgs.kmix
      pkgs.libv4l
      pkgs.libvirt
      pkgs.networkmanager
      pkgs.networkmanager-openconnect
      pkgs.networkmanagerapplet
      pkgs.pavucontrol
      pkgs.pipewire
      pkgs.plasma-desktop
      pkgs.plasma-integration
      pkgs.plasma-pa
      pkgs.rtkit
      pkgs.sddm
      pkgs.xorg.xauth
      pkgs.yakuake
    ];

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
  };
}
