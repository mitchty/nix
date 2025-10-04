{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    pciutils
    mcelog
  ];
}
