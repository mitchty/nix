{ lib, pkgs, options, config, ... }:

let
  name = "gui";
in
{
  options.roles.${name} = {
    enable = lib.mkEnableOption "For now used to indicate a system is/n't one that has a graphical login.";

    # TODO: Maybe the answer lies here? https://gist.github.com/udf/4d9301bdc02ab38439fd64fbda06ea43
    isLinux = lib.mkOption {
      default = false;
      defaultText = "false";
      description = "Avoid a stupid infinite recursion I have no idea how to debug atm";
      type = lib.types.bool;
    };

    isDarwin = lib.mkOption {
      default = false;
      defaultText = "false";
      description = "Avoid a stupid infinite recursion I have no idea how to debug atm";
      type = lib.types.bool;
    };

  };

  # darwin is ignored for now, mostly just a boolean oracle for home-manager there
  config = lib.mkIf config.roles.${name}.enable (lib.mkMerge [
    (lib.optionalAttrs (options ? launchd) (lib.mkIf (config.roles.${name}.isDarwin) { }))

    (lib.optionalAttrs (options ? systemd) (lib.mkIf (config.roles.${name}.enable) {
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

      # Enable the Plasma 5 Desktop Environment for xorg.
      services.xserver = {
        enable = true;
        layout = "us";

        libinput = {
          enable = true;
          touchpad = {
            naturalScrolling = true;
            accelProfile = "adaptive";
          };
        };

        xkbVariant = "";

        displayManager.sddm.enable = true;
        desktopManager.plasma5.enable = true;

        xkbOptions = lib.concatStringsSep "," [
          # Capslock is control, I'm not a heathen.
          #          "ctrl:swapcaps"
          "ctrl:nocaps"
        ];

        config = (lib.mkAfter ''
          Section "InputClass"
            Identifier "NaturalScrollingScrolling for touchpads"
            Driver "libinput"
            MatchIsPointer "on"
            Option "NaturalScrolling" "on"
          EndSection
        '');
      };
    }))
  ]);
}
