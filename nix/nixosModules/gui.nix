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

    type = lib.mkOption {
      default = "X";
      example = "wayland";
      description = "What kind of gui is this";
      type = lib.types.enum [
        "X"
        "wayland"
      ];
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
    environment.systemPackages =
      with pkgs;
      [
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
        #      libv4l
        libvirt
        networkmanager
        networkmanager-openconnect
        networkmanagerapplet
        pavucontrol
        pipewire
        rtkit
        bitwarden-desktop
      ]
      ++ lib.optionals (config.services.mitchty.gui.type == "X") [
        kdePackages.sddm
        xorg.xauth
        xclip
        kdePackages.plasma-desktop
        kdePackages.plasma-integration
        kdePackages.plasma-pa
        kdePackages.kmix
      ]
      ++ lib.optionals (config.services.mitchty.gui.type == "wayland") [
        mako
        wl-clipboard
        slurp
        grim
        wdisplays
        cliphist
        gscreenshot
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
      #      sway.enable = true;
      sway = lib.mkIf (config.services.mitchty.gui.type == "wayland") {
        enable = true;
        wrapperFeatures.gtk = true;
        extraOptions = [
          "--unsupported-gpu"
          "--verbose"
        ];
      };
      #      sway.enable =  {true;};
      #      steam.enable = true;
    };

    services = {
      gnome.gnome-keyring = lib.mkIf (config.services.mitchty.gui.type == "wayland") { enable = true; };

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

      displayManager.defaultSession = lib.mkIf (config.services.mitchty.gui.type == "X") "xfce+i3";

      # Note xserver is a bit of a misnomer in nixos its more "gui". Path
      # dependence for when x was the only option. Will leave myself an out for
      # xorg until I get things to good.
      xserver = lib.mkMerge [
        (lib.mkIf (config.services.mitchty.gui.type == "wayland") {
          enable = true;
          # displayManager.gdm.enable = true;
          # desktopManager.gnome.enable = true;
        })

        (lib.mkIf (config.services.mitchty.gui.type == "X") {
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
        })
      ];

      # wayland = lib.mkIf (config.services.mitchty.gui.type == "wayland") {
      #   windowManagers.sway = {
      #     enable = true;
      #     config = rec {
      #       modifier = "Mod4"; # Super key
      #       terminal = "alacritty";
      #       output = {
      #         "Virtual-1" = {
      #           mode = "1920x1080@60Hz";
      #         };
      #       };
      #     };
      #     extraConfig = ''
      #       bindsym Print               exec shotman -c output
      #       bindsym Print+Shift         exec shotman -c region
      #       bindsym Print+Shift+Control exec shotman -c window

      #       output "*" bg /etc/foggy_forest.jpg fill
      #     '';
      #   };
      # };
    };
  };
}
