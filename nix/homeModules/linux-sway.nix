{
  pkgs,
  lib,
  config,
  ...
}:
let
  enableFullBuild = import ../../hacks/flake-check.nix pkgs.stdenv.hostPlatform.system;

  # TODO: have fontsize be a configuration option?
  fontSize = 16;
  fontName = "Comic Code Bold";
  mystatus =
    (pkgs.writeScriptBin "mystatus" (builtins.readFile ../../src/mystatus.sh)).overrideAttrs
      (old: {
        buildCommand = "${old.buildCommand}\n patchShebangs $out";
      });

  # note rocm/amd gpu support doesn't exist yet so won't display usage on the
  # win max lappy
  # https://github.com/joular/powerjoular/issues/67
  powerjoular-status = pkgs.writeShellScriptBin "powerjoular-status" ''
    csv="/run/powerjoular/powerjoular.csv"
    if [ ! -f "$csv" ]; then
      echo '{"text":"csv issue","tooltip":"PowerJoular data not available"}'
      exit 0
    fi

    tot=$(cat "$csv" | ${pkgs.gawk}/bin/awk -F',' '{print $3}')
    cpu=$(cat "$csv" | ${pkgs.gawk}/bin/awk -F',' '{print $4}')
    gpu=$(cat "$csv" | ${pkgs.gawk}/bin/awk -F',' '{print $5}')

    text=$(printf "%.1fW" "$tot")
    tooltip=$(printf "CPU: %.1fW\\\nGPU: %.1fW" "$cpu" "$gpu")
    printf '{"text": "%s", "tooltip": "%s"}' "$text" "$tooltip"
  '';

  sway-window-info = pkgs.writeShellScriptBin "sway-window-info" ''
    # Show info about currently focused window or all windows
    if [ "$1" = "-a" ] || [ "$1" = "--all" ]; then
      echo "All visible windows:"
      ${pkgs.sway}/bin/swaymsg -t get_tree | ${pkgs.jq}/bin/jq -r '.. | select(.app_id? or .window_properties?) | "\(.app_id // .window_properties.class // "unknown") - \(.name)"' | sort -u
    else
      echo "Currently focused window:"
      ${pkgs.sway}/bin/swaymsg -t get_tree | ${pkgs.jq}/bin/jq '.. | select(.focused? == true) | {app_id, name, class: .window_properties.class, instance: .window_properties.instance}'
    fi
  '';

  weather-with-class = pkgs.writeShellScriptBin "weather-with-class" ''
    json=$(${pkgs.wttrbar}/bin/wttrbar --location 'Saint Paul, MN' --fahrenheit --mph --ampm)
    temp=$(echo "$json" | ${pkgs.jq}/bin/jq -r '.text' | grep -oE '[0-9]+' | head -1)

    if [ -z "$temp" ]; then
      echo "$json"
      exit 0
    fi

    if [ "$temp" -le 32 ]; then
      class="freezing"
    elif [ "$temp" -le 50 ]; then
      class="cold"
    elif [ "$temp" -le 70 ]; then
      class="mild"
    elif [ "$temp" -le 85 ]; then
      class="warm"
    else
      class="hot"
    fi

    echo "$json" | ${pkgs.jq}/bin/jq --arg cls "$class" '. + {class: $cls}'
  '';

  pastelGreen = "#c8e6c9";
  pastelBlue = "#bbdefb";
  pastelRed = "#ffb3ba";
  pastelYellow = " #fff9c4";

  white = "#ffffff";
  black = "#000000";
in
{
  config = {
    services = {
      mako = {
        enable = true;
        settings = {
          default-timeout = 5000;
          ignore-timeout = 3000;
        };
        extraConfig = /* toml */ ''
          background-color=${pastelBlue}
          text-color=${black}
          border-color=${pastelBlue}

          [urgency=low]
          border-color=${pastelYellow}

          [urgency=normal]
          border-color=${pastelGreen}

          [urgency=high]
          border-color=${pastelRed}
        '';
      };
      swayidle = {
        enable = true;
        timeouts = [
          {
            timeout = 1200;
            command = "${pkgs.swaylock}/bin/swaylock -fF -c 00000000";
          }
        ];
      };
    };

    programs.waybar = {
      enable = true;
      style = ''
        * {
          font-family: "${fontName}";
          font-size: ${toString fontSize}px;
        }

        window#waybar {
          background-color: ${black};
          color: ${white};
        }

        #cpu {
          background-color: ${pastelGreen};
          color: ${black};
          padding: 0 10px;
        }

        #cpu.warning {
          background-color:${pastelYellow};
          color: ${black};
        }

        #cpu.critical {
          background-color: ${pastelRed};
          color: ${black};
        }

        #memory {
          background-color: ${pastelGreen};
          color: ${black};
          padding: 0 10px;
        }

        #memory.warning {
          background-color:${pastelYellow};
          color: ${black};
        }

        #memory.critical {
          background-color: ${pastelRed};
          color: ${white};
        }

        #network {
          background-color: transparent;
          color: ${white};
          padding: 0 10px;
        }

        #pulseaudio {
          background-color: ${pastelBlue};
          color: ${black};
          padding: 0 10px;
        }

        #pulseaudio.muted {
          background-color: ${pastelRed};
          color: ${white};
        }

        #clock.time,
        #clock.date {
          background-color: transparent;
          color: ${white};
          padding: 0 10px;
        }
      '';
      settings = {
        mainBar = {
          layer = "bottom";
          position = "top";
          height = 40;
          modules-left = [
            "sway/workspaces"
            "sway/mode"
          ];

          modules-center = [
            "custom/weather"
            # "sway/window"
          ];

          modules-right = [
            #            "bluetooth"
            "cpu"
            "memory"
            #            "custom/gpu"
            "temperature"
            #            "battery"
            "pulseaudio"
            "custom/power"
            "clock#date"
            "clock#time"
            "tray"
            "network"
          ];

          # battery = {
          #   "interval" = 10;
          #   "states" = {
          #     "warning" = 30;
          #     "critical" = 15;
          #   };
          #   # Connected to AC
          #   "format" = "  {icon}  {capacity}%"; # Icon: bolt
          #   # Not connected to AC
          #   "format-discharging" = "{icon}  {capacity}%";
          #   "format-icons" = [
          #     "" # Icon= battery-full
          #     "" # Icon= battery-three-quarters
          #     "" # Icon= battery-half
          #     "" # Icon= battery-quarter
          #     "" # Icon= battery-empty
          #   ];
          #   "tooltip" = true;
          # };

          "clock#time" = {
            interval = 1;
            format = "{:%H:%M:%S}";
          };

          "clock#date" = {
            interval = 10;
            format = "{:%Y-%m-%d}";
            "tooltip-format" = "<tt>{calendar}</tt>";
          };

          "cpu" = {
            interval = 5;
            format = "cpu {usage}%";
            states = {
              warning = 60;
              critical = 90;
            };
          };

          memory = {
            interval = 5;
            format = "mem {}%";
            states = {
              warning = 60;
              critical = 90;
            };
          };

          network = {
            interval = 5;
            "format-wifi" = "?  {essid} ({signalStrength}%)";
            "format-ethernet" = "{ifname}: {ipaddr}/{cidr}";
            "format-disconnected" = "⚠  Disconnected";
            "tooltip-format" = "{ifname}: {ipaddr}";

          };

          "sway/mode" = {
            "format" = "<span style=\"italic\">  {}</span>";
            "tooltip" = false;
          };

          "sway/window" = {
            format = "{}";
            "max-length" = 120;
          };

          pulseaudio = {
            "scroll-step" = 2;
            "format" =
              "<span font_family='Font Awesome v4 Compatibility' font_size='larger'>{icon}</span>  {volume}%";
            "format-muted" = "🔇";
            "format-icons" = {
              "headphones" = "🎧";
              "headset" = "?";
              "default" = [
                "🔉"
                "🔊"
              ];
            };
            "on-click" = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          };

          temperature = {
            "critical-threshold" = 80;
            "interval" = 5;
            "format" = "{icon}  {temperatureC}°C";
            "format-icons" = [
              "a" # / Icon: temperature-empty
              "b" # / Icon: temperature-quarter
              "c" # / Icon: temperature-half
              "d" # / Icon: temperature-three-quarters
              "e" # / Icon: temperature-full
            ];
            "tooltip" = true;
          };

          "tray" = {
            "icon-size" = 21;
            "spacing" = 10;
          };

          "custom/weather" = {
            "format" = "{}° ";
            "tooltip" = true;
            "interval" = 3600;
            "exec" = "${pkgs.wttrbar}/bin/wttrbar --location 'Saint Paul, MN' --fahrenheit --mph --ampm";
            "return-type" = "json";
          };

          "custom/power" = {
            "format" = "⚡ {}";
            "interval" = 5;
            "exec" = "${powerjoular-status}/bin/powerjoular-status";
            "return-type" = "json";
          };

          # "custom/gpu" = {
          #   "format" = "GPU {}°";
          #   "tooltip" = true;
          #   "interval" = 10;
          #   "exec" = "nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits";
          #   "return-type" = "csv";
          # };

          # "bluetooth" = {
          #   "format" = " {status}";
          #   "format-connected" = " {device_alias}";
          #   "format-connected-battery" = " {device_alias} {device_battery_percentage}%";
          #   #/ "format-device-preference": [ "device1", "device2" ], // preference list deciding the displayed device
          #   "tooltip-format" = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
          #   "tooltip-format-connectee" =
          #     "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
          #   "tooltip-format-enumerate-connected" = "{device_alias}\t{device_address}";
          #   "tooltip-format-enumerate-connected-battery" =
          #     "{device_alias}\t{device_address}\t{device_battery_percentage}%";
          #   "on-click-right" = "rfkill toggle bluetooth";
          # };
        };

      };
    };

    wayland.windowManager.sway = {
      enable = true;
      package = pkgs.unstable.sway;
      checkConfig = false; # Disable config check to avoid nixpkgs version conflicts
      extraOptions = [
        "--unsupported-gpu"
        "--verbose"
      ];

      #   systemd.enable = true;
      #   wrapperFeatures.gtk = true;

      config = {
        terminal = lib.getExe pkgs.kitty;

        modifier = "Mod4";

        defaultWorkspace = "workspace number 1";

        startup = [
          { command = "kitty"; }
          { command = "emacs"; }
          { command = "firefox"; }
          { command = "google-chrome-stable"; }
          # non gooey programs
          { command = "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch cliphist store"; }
          { command = "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch cliphist store"; }
        ];

        keybindings =
          let
            # execSpawn = cmd: "exec ${pkgs.spawn}/bin/spawn ${cmd}";
            execSpawn = cmd: "exec ${cmd}";

            inherit (config.wayland.windowManager.sway.config) modifier terminal;
          in
          lib.mkOptionDefault {
            "${modifier}+Return" = execSpawn (lib.getExe pkgs.kitty);
            # "${modifier}+d" = execSpawn "${pkgs.drunmenu-wayland}/bin/drunmenu";
            # "${modifier}+m" = execSpawn "${pkgs.emojimenu-wayland}/bin/emojimenu";
            # "${modifier}+q" = execSpawn "swaylock -f";
            # "Print" = execSpawn "${pkgs.screenshot}/bin/screenshot";
          };

        bars = [
          {
            colors = {
              statusline = "${black}";
              background = "#323232";
              inactiveWorkspace = {
                background = "#32323200";
                border = "#32323200";
                text = "#5c5c5c";
              };
            };
            position = "top";
            command = "waybar";
          }
        ];

        assigns = {
          # "1" = [
          #   { app_id = "kitty"; }
          #   { app_id = "emacs"; }
          # ];
          "2" = [ { app_id = "firefox"; } ];
          "3" = [ { app_id = "google-chrome"; } ];
          "4" = [
            { app_id = "steam"; }
            { app_id = "TradingView"; }
          ];
        };

        window.commands = [
          {
            criteria = {
              app_id = "firefox";
              title = "Picture-in-Picture";
            };
            command = "floating enable, sticky on, move position 50 px 50 px";
          }
          {
            criteria.window_role = "pop-up";
            command = "floating enable";
          }
          {
            criteria.window_role = "bubble";
            command = "floating enable";
          }
          {
            criteria.window_type = "dialog";
            command = "floating enable";
          }
          {
            criteria.window_type = "menu";
            command = "floating enable";
          }
        ];

        output = {
          "HDMI-A-2" = {
            resolution = "7680x2160";
          };
        };
      };

    };

    home = {
      #       export XDG_SESSION_TYPE=wayland
      # export XDG_SESSION_DESKTOP=sway
      # export XDG_CURRENT_DESKTOP=sway
      # export MOZ_ENABLE_WAYLAND=1
      # export QT_QPA_PLATFORM=wayland
      sessionVariables = {
        MOZ_ENABLE_WAYLAND = "1";
        QT_QPA_PLATFORM = "wayland";
        SDL_VIDEODRIVER = "wayland";

        MOZ_DBUS_REMOTE = "1";
        MOZ_USE_XINPUT2 = "1";

        QT_AUTO_SCREEN_SCALE_FACTOR = "1";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        QT_WAYLAND_FORCE_DPI = "physical";

        # WLR_RENDERER = "vulkan"; needed?
        XWAYLAND_NO_GLAMOR = "1"; # needed?
      };

      packages = with pkgs; [
        # ass ksnip
        # testing this snapshot util
        gradia
        xdg-desktop-portal
        xdg-desktop-portal-wlr
        xdg-desktop-portal-gnome
        mystatus
        sway-window-info
        powerjoular-status
        bc
        (lib.hiPrio (
          google-chrome.override {
            # Some of these flags correspond to chrome://flags
            commandLineArgs = [
              #chromium --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-webrtc-pipewire-capturer
              "--enable-features=UseOzonePlatform"
              "--ozone-platform=wayland"
              "--enable-webrtc-pipewire-capturer"
              # no work?
              # # Correct fractional scaling.
              # "--ozone-platform-hint=wayland"
              # # Hardware video encoding on Chrome on Linux.
              # # See chrome://gpu to verify.
              # "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder"
            ];
          }
        ))
      ];

      # # TODO: convert to wayland.windowManager.sway
      # file.".config/sway/config" = {
      #   text = pkgs.lib.strings.concatStringsSep "\n" (
      #     [
      #       (pkgs.lib.strings.fileContents ../../static/wayland/sway/config)
      #     ]
      #     ++ [
      #       ''
      #         # Font for window titles and bar.
      #         font pango:${fontName} 12

      #         bar {
      #                 position top
      #                 status_command ${../../src/mystatus.sh}
      #         }
      #       ''
      #     ]
      #   );
      #   force = true; # I can't get why I need to set force for ~/.config/i3* stuff
      # };
    };

    programs.kitty = {
      enable = true;
      # The font derivation is the only thing thats actually failing on macos
      # with nix flake check.
      font = {
        name = fontName;
        package = lib.optionalAttrs enableFullBuild pkgs.comic-code or null;
        #        package = null;
        size = fontSize;
      };
      shellIntegration.enableZshIntegration = true;
      #    theme = "Spring";
      settings = {
        enable_audio_bell = false;
        visual_bell_duration = "0.1";
        tab_bar_style = "slant";
        term = "xterm-256color";
      };
    };
  };
}

#   packages = with pkgs; [
#     networkmanager-openconnect
#     unstable.teams-for-linux
#   ];
# };
# Kitty only makes sense on i3.... for now?
