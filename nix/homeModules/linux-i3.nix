{
  pkgs,
  lib,
  ...
}:
let
  mylib = import ../lib.nix { inherit lib; };
  enableFullBuild = mylib.enableFullBuild pkgs.stdenv.hostPlatform.system;

  # Default font size based off display size in role, basically big or else...
  #fontSize = if roles.gui-new.displaySize == "big" then 14 else 12;
  fontSize = 12;
  fontName = "Comic Code Bold";
  mystatus =
    (pkgs.writeScriptBin "mystatus" (builtins.readFile ../../src/mystatus.sh)).overrideAttrs
      (old: {
        buildCommand = "${old.buildCommand}\n patchShebangs $out";
      });
in
{
  config = {
    home = {
      packages = with pkgs; [
        mystatus
        bc
      ];

      file.".config/i3/config" = {
        text = pkgs.lib.strings.concatStringsSep "\n" (
          [
            (pkgs.lib.strings.fileContents ../../static/xorg/i3/config)
          ]
          ++ [
            ''
              # Font for window titles and bar.
              font pango:${fontName} 12
            ''
          ]
        );
        force = true; # I can't get why I need to set force for ~/.config/i3* stuff
      };
    };

    programs.kitty = lib.optionalAttrs enableFullBuild {
      enable = true;
      font = {
        name = fontName;
        package = pkgs.comic-code;
        size = fontSize;
      };
      shellIntegration.enableZshIntegration = true;
      #    theme = "Spring";
      extraConfig = ''
        enable_audio_bell no
        visual_bell_duration 0.1
        tab_bar_style slant
        term=xterm-256color
      '';
    };
  };
}

#   packages = with pkgs; [
#     networkmanager-openconnect
#     unstable.teams-for-linux
#   ];
# };
# Kitty only makes sense on i3.... for now?
