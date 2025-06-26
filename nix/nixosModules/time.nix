# ssh config
{
  # Let me ssh in by default
  services.chrony = {
    enable = true;
    servers = [
      "pool.ntp.org"
      "pool.ntp.org"
      "pool.ntp.org"
      "time.apple.com"
    ];
  };
}
