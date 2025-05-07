{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  system = {
    defaults = {
      trackpad = {
        Clicking = true;
        TrackpadRightClick = true;
      };
    };
  };
}
