{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
{
  # Don't explicitly set identityPaths - let it use defaults
  # which should work for both user keys and system host keys

  # age.secrets."secrets/canary" = {
  #   file = ../../secrets/canary.age;
  #   path = config.home.homeDirectory + "/.age-canary";
  # };
}
