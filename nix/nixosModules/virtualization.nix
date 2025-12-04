{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Use/setup libvirtd/docker note libvirtd requires polkit to work in 22.11+
  security.polkit.enable = true;

  environment = {
    variables.LIBVIRT_DEFAULT_URI = "qemu:///system";
    systemPackages = with pkgs; [
      virtiofsd
    ];
  };

  users.users.mitch.extraGroups = [ "libvirtd" ];

  virtualisation = {
    libvirtd = {
      enable = true;
      #      extraOptions = [ "--verbose" ];
      nss = {
        enable = true;
        enableGuest = true;
      };

      qemu.runAsRoot = false;
    };
  };

  boot = {
    kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = "1";
      "net.ipv4.conf.all.bc_forwarding" = "1";
      "net.ipv4.conf.all.mc_forwarding" = "1";
      "net.ipv4.conf.default.forwarding" = "1";
      "net.ipv4.conf.default.bc_forwarding" = "1";
      "net.ipv4.conf.default.mc_forwarding" = "1";
      #      "net.ipv4.conf.all.mc_forwarding" = "1";

      "net.ipv6.conf.all.forwarding" = "1";
      "net.ipv6.conf.all.bc_forwarding" = "1";
      "net.ipv6.conf.all.mc_forwarding" = "1";
      "net.ipv6.conf.default.forwarding" = "1";
      "net.ipv6.conf.default.bc_forwarding" = "1";
      "net.ipv6.conf.default.mc_forwarding" = "1";
      #      "net.ipv6.conf.all.mc_forwarding" = "1";

      "net.ipv4.ip_forward" = "1";
      "net.ipv6.ip_forward" = "1";

      "net.bridge.bridge-nf-call-arptables" = false;
      "net.bridge.bridge-nf-call-ip6tables" = false;
      "net.bridge.bridge-nf-call-iptables" = false;

      # # If we don't disable forwarding for the wan interface, for some reason
      #  # the router advertisements in ipv6 don't work. Linux is effing dumb.
      #  "net.ipv6.conf.br0.forwarding" = 1;
      #  "net.ipv6.conf.br0.accept_ra" = 1;
    };
  };

  # config.shell.core.variables = [{ LIBVIRT_DEFAULT_URI = "qemu:///system"; global = true; }];

  programs.virt-manager.enable = true;

  boot.kernelModules = with config.boot.kernelModules; [
    #    "kvm_amd"
    "kvm_intel"
  ];

  # Top is the video loopback device options
  # kvm_intel nested is set so we can nest vm's in kvm vm's
  boot.extraModprobeConfig = ''
    #    options kvm_amd nested=1
        options kvm_intel nested=1
  '';

  nixpkgs.config.packageOverrides = pkgs: {
    qemu = pkgs.qemu.override { gtkSupport = false; };
  };
}
