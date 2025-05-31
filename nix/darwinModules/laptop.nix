{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  # TODO: battery charging control app https://github.com/actuallymentor/battery
  imports = with inputs.self.darwinModules; [
    trackpad
    controlcenter
  ];
  # For future it'll be this instead:
  security.pam.services.sudo_local.touchIdAuth = true;
}
