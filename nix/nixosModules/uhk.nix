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
  services.udev.extraRules = ''
    # These are the udev rules for accessing the USB interfaces of the UHK as non-root users.
    # Copy this file to /etc/udev/rules.d and physically reconnect the UHK afterwards.
    SUBSYSTEM=="input", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="612[0-7]", GROUP="input", MODE="0660"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="612[0-7]", TAG+="uaccess", MODE="0660", GROUP="input"
    KERNEL=="hidraw*", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="612[0-7]", TAG+="uaccess", MODE="0660", GROUP="input"

    SUBSYSTEM=="input", ATTRS{idVendor}=="37a8", ATTRS{idProduct}=="*", GROUP="input", MODE="0660"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="37a8", ATTRS{idProduct}=="*", TAG+="uaccess", MODE="0660", GROUP="input"
    KERNEL=="hidraw*", ATTRS{idVendor}=="37a8", ATTRS{idProduct}=="*", TAG+="uaccess", MODE="0660", GROUP="input"

    # Streameck rules
    SUBSYSTEM=="usb", ATTR{idVendor}=="0fd9", ATTR{idProduct}=="0060", MODE="0660", GROUP="input"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0fd9", ATTR{idProduct}=="0063", MODE="0660", GROUP="input"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0fd9", ATTR{idProduct}=="006c", MODE="0660", GROUP="input"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0fd9", ATTR{idProduct}=="006d", MODE="0660", GROUP="input"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0fd9", ATTR{idProduct}=="008f", MODE="0660", GROUP="input"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0fd9", ATTR{idProduct}=="0090", MODE="0660", GROUP="input"
  '';

  environment.systemPackages = [
    pkgs.uhk-agent
    pkgs.uhk-udev-rules
  ];
}
