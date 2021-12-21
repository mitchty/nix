{ pkgs, ... }: {
  # For now stick stuff that is "host" specific in here.
  # Little rhyme or reason as to what is inside for now.

  # Use the latest packaged kernel rev
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Use the systemd-boot EFI boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.enableCryptodisk = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.gfxmodeEfi = "1024x768";

  boot.initrd.luks.devices = {
    crypted = {
      device = "/dev/disk/by-uuid/fdd79b6e-151d-476e-aa88-c6f1f2de3fe5";
      preLVM = true;
    };
  };

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.wlp82s0.useDHCP = true;

  # TODO: Keep?
  # Also make sure that we have a virtualspeaker+monitor so audio can be routed
  # from obs to other apps
  # hardware.pulseaudio.extraConfig = ''
  #   load-module module-null-sink sink_name=Virtual-Speaker sink_properties=device.description=Virtual-Speaker
  #   load-module module-remap-source source_name=Remap-Source master=Virtual-Speaker.monitor
  # '';

  services.resolved = {
    enable = true;
    fallbackDns = [ "8.8.8.8" "2001:4860:4860::8844" ];
  };

  services.openvpn.servers = {
    fremont = {
      config = '' config /home/mitch/src/github.com/rancherlabs/fremont/VPN/Ranch01/ranch01-fremont-udp.ovpn '';
      up = "${pkgs.openvpn}/libexec/update-systemd-resolved";
      down = "${pkgs.openvpn}/libexec/update-systemd-resolved";
    };
  };
}
