{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  system = {
    defaults = {
      finder = {
        CreateDesktop = false;
        AppleShowAllExtensions = true;
        FXEnableExtensionChangeWarning = false;
        QuitMenuItem = true;
        ShowPathbar = true;
        _FXShowPosixPathInTitle = true;
      };
    };
  };
}
