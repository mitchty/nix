{
  pkgs,
  ...
}:
let
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
  };
}
