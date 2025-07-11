{ lib, ... }:
{
  #  users.users.mitch.openssh.authorizedKeys.keys = builtins.readFile ../pub.key;
  users.extraUsers.mitch.openssh.authorizedKeys.keys = [
    (builtins.readFile ../pub.key)
  ];
}
