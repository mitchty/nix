{ ... }: {
  networking.networkmanager.enable = false;
  networking.enableIPv6 = false;

  # Enable ntp
  services.chrony = {
    enable = true;
    servers = [
      "pool.ntp.org"
      "pool.ntp.org"
      "pool.ntp.org"
      "time.apple.com"
    ];
  };

  # Default queueing discipline will be controlled delay
  boot.kernel.sysctl."net.core.default_qdisc" = "fq_codel";

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
}
