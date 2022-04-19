{ ... }: {
  networking.firewall.allowedTCPPorts = [ 3389 3350 5900 22000 3900 3901 3902 9333 8080 8888 8333 ];

  networking.firewall.allowedUDPPorts = [ 5353 ];
  networking.firewall.allowedUDPPortRanges = [{ from = 21027; to = 21027; } { from = 22000; to = 22000; } { from = 60000; to = 60010; }];

  networking.networkmanager.enable = true;
  networking.enableIPv6 = false;

  # Enable ntp
  services.timesyncd.enable = true;

  # Default queueing discipline will be controlled delay
  boot.kernel.sysctl."net.core.default_qdisc" = "fq_codel";

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
}
