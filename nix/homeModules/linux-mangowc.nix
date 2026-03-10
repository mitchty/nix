{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = {
    wayland.windowManager.mango = {
      enable = true;

      settings = ''
        monitor = HDMI-A-2,7680x2160,0x0,1

        $mod = SUPER

        general {
          gaps_in = 5
          gaps_out = 10
          border_size = 2
        }

        input {
          kb_layout = us
          follow_mouse = 1
        }

        bind = $mod, Return, exec, kitty
        bind = $mod SHIFT, Q, killactive
        bind = $mod SHIFT, E, exit
        bind = $mod, F, fullscreen
        bind = $mod, V, togglefloating

        bind = $mod, 1, workspace, 1
        bind = $mod, 2, workspace, 2
        bind = $mod, 3, workspace, 3
        bind = $mod, 4, workspace, 4
        bind = $mod, 5, workspace, 5

        bind = $mod SHIFT, 1, movetoworkspace, 1
        bind = $mod SHIFT, 2, movetoworkspace, 2
        bind = $mod SHIFT, 3, movetoworkspace, 3
        bind = $mod SHIFT, 4, movetoworkspace, 4
        bind = $mod SHIFT, 5, movetoworkspace, 5
      '';

      autostart_sh = ''
        kitty &
        emacs &
        firefox &
        google-chrome-stable &
      '';
    };

    services.mako = {
      enable = true;
      settings = {
        default-timeout = 5000;
      };
    };

    home.packages = with pkgs; [
      wl-clipboard
      slurp
      grim
    ];
  };
}
