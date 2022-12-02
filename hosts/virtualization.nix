{ config, ... }: {
  # TODO: make this stuff into a module/option system so I can separate out the
  # video for linux loopback stuff from the kvm related stuff.
  # For the qemu-agent integration for kvm/qemu
  services.qemuGuest.enable = true;

  # Use/setup libvirtd/docker note libvirtd requires polkit to work in 22.11
  security.polkit.enable = true;
  virtualisation.libvirtd.enable = true;
  virtualisation.docker.enable = true;

  # Loopback device/kernel module config for obs
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
  boot.kernelModules = with config.boot.kernelModules; [
    "v4l2loopback"
    "kvm_intel"
  ];

  # Top is the video loopback device options
  # kvm_intel nested is set so we can nest vm's in kvm vm's
  boot.extraModprobeConfig = ''
    options kvm_intel nested=1
    options v4l2loopback exclusive_caps=1 video_nr=9 card_label="obs"
  '';

  nixpkgs.config.packageOverrides = pkgs: {
    qemu = pkgs.qemu.override { gtkSupport = true; };
  };
}
