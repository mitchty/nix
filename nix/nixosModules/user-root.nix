{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  environment.variables.EDITOR = "vi";

  age.secrets = {
    "secrets/passwd/root" = {
      file = ../../secrets/passwd/root.age;
    };
  };

  users = {
    # Only users I define
    mutableUsers = false;

    users.root = {
      hashedPassword = lib.mkForce null;
      hashedPasswordFile = config.age.secrets."secrets/passwd/root".path;
    };
  };
}
