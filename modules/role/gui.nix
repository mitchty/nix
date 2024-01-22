{ config, lib, pkgs, options, ... }:

with lib;

let
  name = "gui";
  cfg = config.role.${name};
in
{
  options.role.${name} = {
    enable = mkEnableOption "For now used to indicate a system is/n't one that has a graphical login.";
  };

  # darwin is ignored for now, mostly just a boolean there.
  config = mkIf cfg.enable
    (optionalAttrs (options ? systemd.services) (mkIf (pkgs.hostPlatform.isLinux) {
      # Only allow certain unfree packages to install
      nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
        "google-chrome"
      ];

      environment.systemPackages = (lib.attrVals [
        "element-desktop"
        "google-chrome"
        "intel-media-driver"
        "kmix"
        "libv4l"
        "libvirt"
        "networkmanager"
        "networkmanager-openconnect"
        "networkmanagerapplet"
        "pavucontrol"
        "pipewire"
        "plasma-desktop"
        "plasma-integration"
        "plasma-pa"
        "rtkit"
        "sddm"
        "xorg.xauth"
        "yakuake"
      ]
        pkgs);

      # Capslock is control, I'm not a heathen.
      services.xserver.xkbOptions = "ctrl:swapcaps";

      # Configure keymap in X11
      services.xserver.layout = "us";

      # Configure dri/vaapi support for ffmpeg so OBS can use the intel hardware encoding
      hardware.opengl = {
        driSupport = true;
        driSupport32Bit = true;
        extraPackages = (lib.attrVals [
          "vaapiIntel"
          "intel-media-driver"
        ]
          pkgs);
      };
      environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

      # Enable the Plasma 5 Desktop Environment.
      services.xserver.enable = true;
      services.xserver.displayManager.sddm.enable = true;
      services.xserver.desktopManager.plasma5.enable = true;
    }));
}