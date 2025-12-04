{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    ethtool
    mcelog
    pciutils
    strace
  ];
}
