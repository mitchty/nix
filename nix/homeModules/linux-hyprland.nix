{
  pkgs,
  lib,
  config,
  ...
}:
let
  fontSize = 16;
  fontName = "Comic Code Bold";
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

        windowrulev2 = [
          "workspace 2, class:^(firefox)$"
          "workspace 3, class:^(google-chrome)$"
        ];
      };
    };

    home = {
      # Session variables moved to linux-wayland.nix to avoid conflicts
      # Desktop-specific session variables (XDG_CURRENT_DESKTOP, etc.) are set by the session itself

      packages = with pkgs; [
        waybar
        mako
        wl-clipboard
        slurp
        grim
        xdg-desktop-portal-hyprland
      ];
    };

    # kitty configuration moved to linux-wayland.nix to avoid duplication
  };
}
