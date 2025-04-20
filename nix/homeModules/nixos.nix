{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  inherit (builtins) mapAttrs;
  inherit (inputs) self;
in
{
  imports = with self.homeModules; [ common ];

  home = {
    stateVersion = "24.11";
  };

  # gui-packages = with pkgs; [
  #   librewolf
  #   gimp
  #   libreoffice
  #   showtime
  #   amberol
  #   fragments
  #   gnome-decoder
  #   eyedropper
  #   errands
  #   firefox
  #   ungoogled-chromium
  # ];
  # };

  # programs = mapAttrs (_: v: v // { enable = true; }) {
  #   gpg.homedir = "${config.xdg.dataHome}/gnupg";
  #   password-store = {
  #     package = pkgs.pass-wayland.withExtensions (exts: [ exts.pass-otp ]);
  #     settings = {
  #       PASSWORD_STORE_CLIP_TIME = "10";
  #       PASSWORD_STORE_GENERATED_LENGTH = "16";
  #       PASSWORD_STORE_DIR = "${config.xdg.dataHome}/pass";
  #       PASSWORD_STORE_SIGNING_KEY = "C4F4D63E4C22651B053D0848DE26C77562110E92";
  #     };
  #   };
  # };
}
