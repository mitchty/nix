{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
{
  # Misc crap that doesn't entirely fit in other "groups"?
  #
  # I dunno its useful stuff just not sure its needed all the time.
  home = {
    packages = with pkgs; [
      #      ipatool
    ];
  };
}
