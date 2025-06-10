{
  pkgs,
  ...
}:
{
  # Power related utilites that only apply to linux (afaik)
  home.packages = [ pkgs.powerjoular ];
}
