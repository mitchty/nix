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

  fontSize = 16;
  fontName = "Comic Code Bold";
in
{
  # Fonts trigger builds on the destination platform if cross checking but
  # normally we always want them
  home.packages = lib.optionals enableFullBuild [
    pkgs.comic-code
    pkgs.pragmata-pro
    # These two so I can read Japanese at least, otherwise chrome displays
    # literally nothing. Not even broken text.
    pkgs.noto-fonts-cjk-sans
    pkgs.noto-fonts-cjk-serif
  ];

  fonts.fontconfig.enable = enableFullBuild;

  # Common kitty configuration for all wayland window managers
  programs.kitty = {
    enable = true;
    font = {
      name = fontName;
      package = if enableFullBuild then (pkgs.comic-code or null) else null;
      size = fontSize;
    };
    shellIntegration.enableZshIntegration = true;
    settings = {
      enable_audio_bell = false;
      visual_bell_duration = "0.1";
      tab_bar_style = "slant";
      term = "xterm-256color";
      wayland_titlebar_color = "system";
    };
  };
}
