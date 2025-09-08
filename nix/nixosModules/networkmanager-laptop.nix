{
  networking = {
    wireless.enable = false;
    networkmanager = {
      enable = true;
      wifi.powersave = false;
      dns = "dnsmasq";
    };
  };
}
