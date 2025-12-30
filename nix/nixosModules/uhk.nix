{ pkgs, lib, ... }:
{
  # nixpkgs = {
  #   config.allowUnfreePredicate =
  #     pkg:
  #     builtins.elem (lib.getName pkg) [
  #       "uhk-agent"
  #       "uhk-udev-rules"
  #     ];
  # };
  services.udev = {
    enable = true;
    extraRules = ''
      SUBSYSTEM=="input", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="612[0-7]", GROUP="users", MODE="0660"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="612[0-7]", TAG+="uaccess", GROUP="users", MODE="0660"
      KERNEL=="hidraw*", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="612[0-7]", TAG+="uaccess", GROUP="users", MODE="0660"

      SUBSYSTEM=="input", ATTRS{idVendor}=="37a8", ATTRS{idProduct}=="*", GROUP="users", MODE="0660"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="37a8", ATTRS{idProduct}=="*", TAG+="uaccess", GROUP="users", MODE="0660"
      KERNEL=="hidraw*", ATTRS{idVendor}=="37a8", ATTRS{idProduct}=="*", TAG+="uaccess", GROUP="users", MODE="0660"
    '';
  };

  environment.systemPackages = [
    pkgs.uhk-agent
    pkgs.uhk-udev-rules
  ];
}
