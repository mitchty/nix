{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.mango.nixosModules.mango
  ];

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
        "both"
      ];
    };

    user = lib.mkOption {
      default = "mitch";
      example = "mitch";
      description = "User to configure home-manager GUI settings for";
      type = lib.types.str;
    };
  };

  config = lib.mkIf config.services.mitchty.gui.enable {
    services.mitchty.powerjoular.enable = lib.mkIf (
      config.services.mitchty.gui.type == "wayland" || config.services.mitchty.gui.type == "both"
    ) true;

    # nixpkgs = {
    #   config.allowUnfreePredicate =
    #     pkg:
    #     builtins.elem (lib.getName pkg) [
    #       "steam"
    #     ];
    # };

    environment.pathsToLink =
      lib.mkIf
        (config.services.mitchty.gui.type == "wayland" || config.services.mitchty.gui.type == "both")
        [
          "/share/applications"
          "/share/xdg-desktop-portal"
          # GDM discovers Wayland sessions from this path; without it none of
          # sway/hyprland/plasma-wayland .desktop files get symlinked into
          # /run/current-system/sw/share and GDM won't see them.
          "/share/wayland-sessions"
          # Same deal for X11 sessions so i3/xfce show up when type="both".
          "/share/xsessions"
        ];

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
        noto-fonts
      ]
      ++
        lib.optionals
          (config.services.mitchty.gui.type == "X" || config.services.mitchty.gui.type == "both")
          [
            kdePackages.sddm
            xorg.xauth
            xclip
            kdePackages.plasma-desktop
            kdePackages.plasma-integration
            kdePackages.plasma-pa
            kdePackages.kmix
          ]
      ++
        lib.optionals
          (config.services.mitchty.gui.type == "wayland" || config.services.mitchty.gui.type == "both")
          [
            wlroots
            mako
            wl-clipboard
            slurp
            grim
            wdisplays
            cliphist
            gscreenshot
            kooha
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

      hyprland =
        lib.mkIf
          (config.services.mitchty.gui.type == "wayland" || config.services.mitchty.gui.type == "both")
          {
            enable = true;
            xwayland.enable = true;
          };

      sway =
        lib.mkIf
          (config.services.mitchty.gui.type == "wayland" || config.services.mitchty.gui.type == "both")
          {
            enable = true;
            wrapperFeatures.gtk = true;
            package = pkgs.unstable.sway;
            extraOptions = [
              "--unsupported-gpu"
              "--verbose"
            ];
          };

      mango =
        lib.mkIf
          (config.services.mitchty.gui.type == "wayland" || config.services.mitchty.gui.type == "both")
          {
            enable = true;
          };
    };

    xdg = {
      menus.enable = true;
      icons.enable = true;

      portal =
        lib.mkIf
          (config.services.mitchty.gui.type == "wayland" || config.services.mitchty.gui.type == "both")
          {
            enable = true;
            # config = {
            #   common = {
            #     default = [ "gtk" ];
            #   };
            #   niri = {
            #     default = [
            #       "gtk"
            #       "gnome"
            #     ];
            #     "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
            #     "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
            #   };
            # };

            # extraPortals = [
            #   pkgs.xdg-desktop-portal-gtk
            #   pkgs.xdg-desktop-portal-gnome
            # ];
            # xdgOpenUsePortal = true;

            # https://github.com/lovesegfault/nix-config/blob/3e4d869fa801c8221a4d3829a64153261d64580c/modules/home/graphical/sway/sway.nix#L70
            # So thats why, xdg-destkop-portal-wlr and sway for current releases
            # don't allow for individual window selection
            # https://github.com/emersion/xdg-desktop-portal-wlr/issues/107#issuecomment-3444983174
            # wayland is AS FREAKING OLD AS X11 WAS WHEN IT WAS CONCEIVED and I
            # can't reliably share windows? WTF software is getting progressively
            # worse.
            # wlr = {
            #   enable = true;
            #   settings = {
            #     screencast = {
            #       max_fps = 60;
            #       output_name = "HDMI-A-2";
            #       chooser_type = "simple";
            #       chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
            #     };
            #   };
            # };
          };
    };

    services = {
      pipewire.wireplumber.enable = true;

      dbus.enable = true;

      gnome.gnome-keyring.enable = true;

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

      displayManager = {
        defaultSession =
          if
            (config.services.mitchty.gui.type == "wayland" || config.services.mitchty.gui.type == "both")
          then
            "hyprland"
          else
            "xfce+i3";

        gdm =
          lib.mkIf
            (config.services.mitchty.gui.type == "wayland" || config.services.mitchty.gui.type == "both")
            {
              enable = true;
              wayland = true;
            };
      };

      # Note xserver is a bit of a misnomer in nixos its more "gui". Path
      # dependence for when x was the only option. Will leave myself an out for
      # xorg until I get things to good.
      desktopManager.plasma6 =
        lib.mkIf
          (config.services.mitchty.gui.type == "wayland" || config.services.mitchty.gui.type == "both")
          {
            enable = true;
          };

      xserver = lib.mkMerge [
        # Enable X server for both wayland (needed for xwayland) and X11
        {
          enable = true;
        }

        # Enable i3 window manager for X11 sessions
        (lib.mkIf (config.services.mitchty.gui.type == "X" || config.services.mitchty.gui.type == "both") {
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

    # Configure home-manager for GUI window managers
    # Wayland sessions: Sway, Hyprland, Plasma (Wayland)
    home-manager.users.${config.services.mitchty.gui.user} = lib.mkMerge [
      (lib.mkIf
        (config.services.mitchty.gui.type == "wayland" || config.services.mitchty.gui.type == "both")
        {
          imports = [
            inputs.self.homeModules.linux-wayland
            # inputs.self.homeModules.linux-sway # renamed to linux-sway.disabled — not ready yet
            inputs.self.homeModules.linux-hyprland
            # mango hm module must be imported here (at the NixOS level where
            # inputs is available) rather than inside linux-mangowc.nix itself,
            # because referencing inputs inside a module's imports = [] list
            # causes infinite recursion.
            inputs.mango.hmModules.mango
            inputs.self.homeModules.linux-mangowc
            inputs.self.homeModules.linux-plasma
          ];
        }
      )

      # X11 sessions: i3, Plasma (X11)
      (lib.mkIf (config.services.mitchty.gui.type == "X" || config.services.mitchty.gui.type == "both") {
        imports = [
          inputs.self.homeModules.linux-i3
        ];
      })
    ];
  };
}
