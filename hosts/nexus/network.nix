{ ... }: {
  networking.firewall.allowedTCPPorts = [ 3389 3350 5900 ];
  networking.firewall.allowedUDPPortRanges = [{ from = 60000; to = 60010; }];
  networking.networkmanager.enable = true;
  networking.enableIPv6 = false;

  # Enable ntp
  services.timesyncd.enable = true;

  # TODO: Lets re-enable ipv6 soon
  boot.kernelParams = [ "ipv6.disable=1" ];

  # Default queueing discipline will be controlled delay
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq_codel";
  };
}
