{
  pkgs,
  lib,
  config,
  ...
}:
let
  fontSize = 16;
  fontName = "Comic Code Bold";

  nvidia-gpu-status = pkgs.writeShellScriptBin "nvidia-gpu-status" ''
    out=$(nvidia-smi \
      --query-gpu=utilization.gpu,utilization.memory,memory.total,memory.free,memory.used \
      --format=csv,noheader,nounits 2>/dev/null) || {
      printf '{"text":"gpu: N/A","tooltip":"nvidia-smi not available"}\n'
      exit 0
    }
    awk_cmd='{ gsub(/ /, ""); split($0, a, ","); print a[1]"|"a[2]"|"a[3]"|"a[4]"|"a[5] }'
    parts=$(echo "$out" | ${pkgs.gawk}/bin/awk -F',' "$awk_cmd")
    gpu_util=$(echo "$parts" | cut -d'|' -f1)
    mem_util=$(echo "$parts" | cut -d'|' -f2)
    mem_total=$(echo "$parts" | cut -d'|' -f3)
    mem_free=$(echo "$parts" | cut -d'|' -f4)
    mem_used=$(echo "$parts" | cut -d'|' -f5)
    text="gpu: ''${gpu_util}% mem: ''${mem_util}%"
    tooltip="total: ''${mem_total} MiB\\\nfree:  ''${mem_free} MiB\\\nused:  ''${mem_used} MiB"
    printf '{"text":"%s","tooltip":"%s"}\n' "$text" "$tooltip"
  '';

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

  pastelGreen = "#c8e6c9";
  pastelBlue = "#bbdefb";
  pastelRed = "#ffb3ba";
  pastelYellow = " #fff9c4";
  white = "#ffffff";
  black = "#000000";
in
{
  config = {
    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = true;
      xwayland.enable = true;

      settings = {
        # Environment variables moved to linux-wayland.nix to avoid duplication
        # env = [ ... ];

        monitor = [
          "HDMI-A-2,7680x2160,0x0,1"
        ];

        exec-once = [
          "waybar"
          "kitty"
          "emacs"
          "firefox"
          "google-chrome-stable"
        ];

        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
        };

        decoration = {
          rounding = 5;
        };

        input = {
          kb_layout = "us";
          follow_mouse = 1;
        };

        "$mod" = "SUPER";

        bind = [
          "$mod, Return, exec, kitty"
          "$mod, D, exec, fuzzel"
          "$mod SHIFT, Q, killactive"
          "$mod SHIFT, E, exit"
          "$mod, F, fullscreen"
          "$mod, V, togglefloating"

          # Workspaces
          "$mod, 1, workspace, 1"
          "$mod, 2, workspace, 2"
          "$mod, 3, workspace, 3"
          "$mod, 4, workspace, 4"
          "$mod, 5, workspace, 5"

          "$mod SHIFT, 1, movetoworkspace, 1"
          "$mod SHIFT, 2, movetoworkspace, 2"
          "$mod SHIFT, 3, movetoworkspace, 3"
          "$mod SHIFT, 4, movetoworkspace, 4"
          "$mod SHIFT, 5, movetoworkspace, 5"
        ];

        # $mod + left-click drag = move floating window
        # $mod + right-click drag = resize floating window
        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];

        windowrulev2 = [
          "workspace 2, class:^(firefox)$"
          "workspace 3, class:^(google-chrome)$"
          "float, title:^(Picture-in-Picture)$"
          "pin, title:^(Picture-in-Picture)$"
          "size 30% 30%, title:^(Picture-in-Picture)$"
          "move 69% 70%, title:^(Picture-in-Picture)$"
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

        #custom-gpu {
          background-color: ${pastelBlue};
          color: ${black};
          padding: 0 10px;
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
            "hyprland/workspaces"
            "hyprland/submap"
          ];

          modules-center = [
            "custom/weather"
          ];

          modules-right = [
            "custom/gpu"
            "cpu"
            "memory"
            "temperature"
            "pulseaudio"
            "custom/power"
            "clock#date"
            "clock#time"
            "tray"
            "network"
          ];

          "clock#time" = {
            interval = 1;
            format = "{:%H:%M:%S}";
          };

          "clock#date" = {
            interval = 10;
            format = "{:%Y-%m-%d}";
            "tooltip-format" = "<tt>{calendar}</tt>";
          };

          cpu = {
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
            interval = 5;
            format = "{icon}  {temperatureC}°C";
            "format-icons" = [
              "a"
              "b"
              "c"
              "d"
              "e"
            ];
            tooltip = true;
          };

          tray = {
            "icon-size" = 21;
            spacing = 10;
          };

          "custom/weather" = {
            format = "{}° ";
            tooltip = true;
            interval = 3600;
            exec = "${pkgs.wttrbar}/bin/wttrbar --location 'Saint Paul, MN' --fahrenheit --mph --ampm";
            "return-type" = "json";
          };

          "custom/gpu" = {
            format = "{}";
            tooltip = true;
            interval = 5;
            exec = "${nvidia-gpu-status}/bin/nvidia-gpu-status";
            "return-type" = "json";
          };

          "custom/power" = {
            format = "⚡ {}";
            interval = 5;
            exec = "${powerjoular-status}/bin/powerjoular-status";
            "return-type" = "json";
          };
        };
      };
    };

    home = {
      # Session variables moved to linux-wayland.nix to avoid conflicts
      # Desktop-specific session variables (XDG_CURRENT_DESKTOP, etc.) are set by the session itself

      packages = with pkgs; [
        fuzzel
        mako
        wl-clipboard
        slurp
        grim
        xdg-desktop-portal-hyprland
        powerjoular-status
        nvidia-gpu-status
      ];
    };

    # kitty configuration moved to linux-wayland.nix to avoid duplication
  };
}
