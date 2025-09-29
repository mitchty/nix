{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.services.mitchty.gui = {
    enable = lib.mkEnableOption "Specify if this is a graphical install or not and if so what type";

    displaySize = lib.mkOption {
      default = "big";
      example = lib.literalExample "big";
      description = "How big of a display are we talkin about here? Options: big, anything else";
      type = lib.types.str;
    };

    gui = lib.mkOption {
      default = "X";
      example = lib.literalExample "X"; # wayland at some point in future?
      description = "What kind of gui is this";
      type = lib.types.str;
    };
  };

  config = lib.mkIf config.services.mitchty.gui.enable {
    # nixpkgs = {
    #   config.allowUnfreePredicate =
    #     pkg:
    #     builtins.elem (lib.getName pkg) [
    #       "steam"
    #     ];
    # };
    environment.systemPackages = with pkgs; [
      dmenu
      gnome-keyring
      element-desktop
      nitrogen
      pasystray
      picom
      polkit_gnome
      pulseaudioFull
      rofi
      nvtopPackages.full
      #      google-chrome
      kdePackages.kmix
      #      libv4l
      libvirt
      networkmanager
      networkmanager-openconnect
      networkmanagerapplet
      parcellite
      pavucontrol
      pipewire
      kdePackages.plasma-desktop
      kdePackages.plasma-integration
      kdePackages.plasma-pa
      rtkit
      kdePackages.sddm
      xorg.xauth
    ];

    # Loopback device/kernel module config for obs
    #    boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];

    hardware.graphics.enable = true;

    #      environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

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
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
      };
    };

    programs = {
      thunar.enable = true;
      dconf.enable = true;
      #      steam.enable = true;
    };

    services = {
      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        jack.enable = true;
        pulse.enable = true;
        socketActivation = true;
      };

      libinput = {
        enable = true;
        touchpad = {
          naturalScrolling = true;
          accelProfile = "adaptive";
        };
      };

      displayManager.defaultSession = "xfce+i3";

      xserver = {
        enable = true;

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

        xkb = {
          variant = "";
          layout = "us";

          options = lib.concatStringsSep "," [
            # Capslock is control, I'm not a heathen.
            #          "ctrl:swapcaps"
            "ctrl:nocaps"
          ];
        };

        # TODO is this and the services.libinput truly needed?
        config = lib.mkAfter ''
          Section "InputClass"
            Identifier "NaturalScrollingScrolling for touchpads"
            Driver "libinput"
            MatchIsPointer "on"
            Option "NaturalScrolling" "on"
          EndSection
        '';
      };
    };
  };
}
