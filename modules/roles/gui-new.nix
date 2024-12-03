{ lib, pkgs, options, config, ... }:

# Going to test out i3 as a dm here
let
  name = "gui-new";
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

    displaySize = lib.mkOption {
      default = "big";
      example = lib.literalExample "big";
      description = "How big of a display are we talkin about here? Options: big, anything else";
      type = lib.types.str;
    };
  };

  # darwin is ignored for now, mostly just a boolean oracle for home-manager there
  config = lib.mkIf config.roles.${name}.enable (lib.mkMerge [
    (lib.optionalAttrs (options ? launchd) (lib.mkIf (config.roles.${name}.isDarwin) { }))

    (lib.optionalAttrs (options ? systemd) (lib.mkIf (config.roles.${name}.enable) {
      environment.systemPackages = with pkgs; [
        terminator
        dmenu
        gnome.gnome-keyring
        element-desktop
        nitrogen
        pasystray
        picom
        polkit_gnome
        pulseaudioFull
        rofi
        google-chrome
        kmix
        libv4l
        libvirt
        networkmanager
        networkmanager-openconnect
        networkmanagerapplet
        parcellite
        pavucontrol
        pipewire
        plasma-desktop
        plasma-integration
        plasma-pa
        rtkit
        sddm
        xorg.xauth
      ];

      # Configure dri/vaapi support for ffmpeg so OBS can use the intel hardware encoding
      hardware.opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
        extraPackages = with pkgs; [
          intel-media-driver
        ];
      };
      environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

      sound.enable = true;

      programs = {
        thunar.enable = true;
        dconf.enable = true;
      };

      security = {
        polkit.enable = true;
        rtkit.enable = true;
      };

      systemd = {
        user.services.polkit-gnome-authentication-agent-1 = {
          description = "polkit-gnome-authentication-agent-1";
          wantedBy = [ "graphical-session.target" ];
          wants = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          serviceConfig = {
            Type = "simple";
            ExecStart =
              "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
            Restart = "on-failure";
            RestartSec = 1;
            TimeoutStopSec = 10;
          };
        };
      };

      # Enable the Plasma 5 Desktop Environment for xorg.
      services.xserver = {
        enable = true;
        layout = "us";
        xkbVariant = "";

        libinput = {
          enable = true;
          touchpad = {
            naturalScrolling = true;
            accelProfile = "adaptive";
          };
        };

        windowManager.i3 = {
          enable = true;
          extraPackages = [ pkgs.i3status ];
        };
        desktopManager = {
          xterm.enable = false;
          xfce = {
            enable = true;
            noDesktop = true;
            enableXfwm = false;
          };
        };
        displayManager = {
          lightdm.enable = true;
          defaultSession = "xfce+i3";
        };

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
