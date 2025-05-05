{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  # For future it'll be this instead:
  #   security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.enableSudoTouchIdAuth = true;
}
