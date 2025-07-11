{ lib, ... }:
{
  users.users.root.openssh.authorizedKeys.keys = [
    (builtins.readFile ../pub.key)
  ];
}
