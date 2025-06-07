{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
{
  imports = [
    inputs.agenix.homeManagerModules.default
  ];

  age.secrets."secrets/canary" = {
    file = ../../secrets/canary.age;
    path = config.home.homeDirectory + "/.age-canary";
  };
}
