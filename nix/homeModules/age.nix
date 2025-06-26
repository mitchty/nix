{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
{
  # TODO: this needs to be in home-manager not nixos....
  age.secrets."secrets/canary" = {
    file = ../../secrets/canary.age;
    path = config.home.homeDirectory + "/.age-canary";
  };
}
