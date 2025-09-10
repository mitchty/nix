{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    pciutils
    tcpdump
    mcelog
  ];
}
