{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
let
  mylib = import ../lib.nix { inherit lib; };
  enableFullBuild = mylib.enableFullBuild pkgs.stdenv.hostPlatform.system;
in
{
  # Setup common to all wayland things what draw crap on screen
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
      # xdg-desktop-portal-wlr
      # xdg-desktop-portal-gnome
      bc
      (lib.hiPrio (
        google-chrome.override {
          # Some of these flags correspond to chrome://flags
          commandLineArgs = [
            #chromium --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-webrtc-pipewire-capturer
            "--enable-features=UseOzonePlatform"
            "--ozone-platform=wayland"
            "--enable-webrtc-pipewire-capturer"
            # TODO: --enable-features="UseOzonePlatform,WaylandLinuxDrmSyncobj,WaylandWindowDecorations,WebRTCPipeWireCapturer,WaylandFractionalScaleV1" --ozone-platform=wayland --enable-webrtc-pipewire-capturer --enable-wayland-ime
            # no work?
            # Hardware video encoding on Chrome on Linux.
            # See chrome://gpu to verify.
            "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder"
          ];
        }
      ))
    ];
  };
}
