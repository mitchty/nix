{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  security.pam.enableSudoTouchIdAuth = true;
}
