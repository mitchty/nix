{
  pkgs,
  ...
}:
{
  # .profile is mostly the same between nixos/macos, all I do is tack on macos stuff to the end of the profile if/when we're there.
  # home.file.".profile".text = lib.strings.fileContents ./.profile + "\n" + lib.strings.optionalString pkgs.stdenv.isDarwin lib.strings.fileContents ./.profile-darwin;
  home.file.".mutagen.yml".source = ../../static/home/mutagen.yaml;
}
